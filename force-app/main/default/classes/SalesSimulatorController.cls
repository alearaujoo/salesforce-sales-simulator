/**
 * @description Controller for the Sales Simulator LWC.
 * Handles product search and order creation logic.
 * @author Charly (Your Name)
 */
public with sharing class SalesSimulatorController {

    /**
     * @description DTO (Data Transfer Object) to map JSON data from LWC to Apex.
     */
    public class ItemRequest {
        @AuraEnabled public String productId;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public Decimal unitPrice;
    }

    /**
     * @description Searches for products based on the user input name.
     * @param searchTerm The string to search for (Product Name or Code).
     * @return List of PricebookEntry records with pricing info.
     */
    @AuraEnabled(cacheable=true)
    public static List<PricebookEntry> searchProducts(String searchTerm) {
        // Sanitize input to prevent SOQL Injection (Best Practice)
        String key = '%' + String.escapeSingleQuotes(searchTerm) + '%';
        
        // We query PricebookEntry to get the List Price directly
        // Ideally, we should filter by the specific Pricebook of the User/Account.
        // For this lab, we use the Standard Pricebook.
        return [
            SELECT Product2.Id, Product2.Name, Product2.ProductCode, UnitPrice 
            FROM PricebookEntry 
            WHERE Pricebook2.IsStandard = true 
            AND IsActive = true
            AND (Product2.Name LIKE :key OR Product2.ProductCode LIKE :key)
            LIMIT 20
        ];
    }

    /**
     * @description Creates an Order and its OrderItems in a single transaction.
     * @param accountId The Customer Account ID.
     * @param items The list of products selected in the LWC (Generic Object List).
     * @return The ID of the created Order.
     */
@AuraEnabled
    public static String createOrder(Id accountId, List<Object> items) {
        Savepoint sp = Database.setSavepoint();
        
        try {
            // 1. Desserializar
            String jsonItems = JSON.serialize(items);
            List<ItemRequest> requestItems = (List<ItemRequest>) JSON.deserialize(jsonItems, List<ItemRequest>.class);

            if (requestItems.isEmpty()) {
                throw new AuraHandledException('O carrinho está vazio.');
            }

            // 2. Definir o Pricebook (Lógica segura que já tínhamos)
            Id pricebookId;
            List<Pricebook2> standardBook = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
            if (!standardBook.isEmpty()) {
                pricebookId = standardBook[0].Id;
            } else {
                pricebookId = [SELECT Id FROM Pricebook2 WHERE IsActive = true LIMIT 1].Id;
            }

            // --- FASE 1: RECOLHER (COLLECT) ---
            // Criamos um conjunto (Set) para armazenar os IDs únicos dos produtos
            Set<Id> productIds = new Set<Id>();
            for (ItemRequest item : requestItems) {
                if (item.productId != null) {
                    productIds.add(item.productId);
                }
            }

            // --- FASE 2: CONSULTAR (QUERY) ---
            // Fazemos UMA única query para buscar todos os preços necessários
            // Nota: Usamos a cláusula 'IN :productIds'
            List<PricebookEntry> pbeList = [
                SELECT Id, Product2Id, UnitPrice 
                FROM PricebookEntry 
                WHERE Product2Id IN :productIds 
                AND Pricebook2Id = :pricebookId
            ];

            // --- FASE 3: MAPEAR (MAP) ---
            // Transformamos a lista num Mapa para acesso rápido
            // Chave: Product2Id (O que o LWC nos enviou)
            // Valor: PricebookEntryId (O que o objeto OrderItem precisa)
            Map<Id, Id> productToPbeMap = new Map<Id, Id>();
            
            for (PricebookEntry pbe : pbeList) {
                productToPbeMap.put(pbe.Product2Id, pbe.Id);
            }

            // 3. Criar o Cabeçalho (Header)
            Order newOrder = new Order(
                AccountId = accountId,
                Status = 'Draft',
                EffectiveDate = Date.today(),
                Pricebook2Id = pricebookId
            );
            insert newOrder;

            // 4. Criar os Itens (Loop Final)
            List<OrderItem> linesToInsert = new List<OrderItem>();
            
            for (ItemRequest item : requestItems) {
                // Em vez de query, consultamos a memória (Mapa). Isto é ultra-rápido.
                Id pbeId = productToPbeMap.get(item.productId);

                // Validação: Se o mapa devolver null, é porque não achámos preço para aquele produto
                if (pbeId == null) {
                    throw new AuraHandledException('Preço não encontrado para o produto ID: ' + item.productId);
                }

                linesToInsert.add(new OrderItem(
                    OrderId = newOrder.Id,
                    Product2Id = item.productId,
                    Quantity = item.quantity,
                    UnitPrice = item.unitPrice,
                    PricebookEntryId = pbeId
                ));
            }

            // DML Fora do Ciclo (Bulk DML) - Sempre!
            insert linesToInsert;

            //Debug
            System.debug('Queries usadas: ' + Limits.getQueries());

            return newOrder.Id;

        } catch (Exception e) {
            Database.rollback(sp);
            System.debug('ERRO CRÍTICO: ' + e.getMessage());
            // Relançar exceção para o LWC
            String errorMessage = e.getMessage().contains('Script-thrown') ? 'Erro interno no servidor.' : e.getMessage();
            throw new AuraHandledException(errorMessage);
        }
    }
}