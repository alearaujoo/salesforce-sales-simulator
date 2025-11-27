import { LightningElement, track, api } from 'lwc';
// Importação dos métodos Apex
import createOrder from '@salesforce/apex/SalesSimulatorController.createOrder';
import getCurrencyRate from '@salesforce/apex/CurrencyService.getCurrencyRate';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SalesSimulator extends LightningElement {
    // --- VARIÁVEIS DE ESTADO ---
    @api recordId; 
    @track cartItems = []; 
    
    // Variáveis para conversão de moeda
    convertedTotal = null;
    selectedCurrency = '';
    exchangeRate = 0;
    isLoading = false;

    // --- GETTERS ---
    get cartHasItems() {
        return this.cartItems.length > 0;
    }

    // Calcula o total e formata em Dólar (padrão do sistema)
    get cartTotal() {
        const total = this.cartItems.reduce((acc, item) => acc + (item.quantity * item.unitPrice), 0);
        
        return new Intl.NumberFormat('en-US', { 
            style: 'currency', 
            currency: 'USD', 
            minimumFractionDigits: 2,
            maximumFractionDigits: 4 
        }).format(total);
    }

    // --- HANDLERS (AÇÕES DO USUÁRIO) ---

    // Adiciona produto vindo do componente filho
    handleProductAdd(event) {
        const product = event.detail;
        
        // Reseta a conversão de moeda pois o valor mudou
        this.convertedTotal = null;

        const existingItem = this.cartItems.find(item => item.productId === product.id);

        if (existingItem) {
            existingItem.quantity += 1;
            existingItem.totalLine = existingItem.quantity * existingItem.unitPrice;
        } else {
            this.cartItems.push({
                productId: product.id,
                productName: product.name,
                quantity: 1,
                unitPrice: product.price,
                totalLine: product.price
            });
        }
    }

    // Remove item do carrinho (Lixeira)
    handleRemoveItem(event) {
        const productIdToRemove = event.target.dataset.id;
        
        // Reseta a conversão de moeda
        this.convertedTotal = null;

        // Filtra criando nova lista sem o item removido
        this.cartItems = this.cartItems.filter(item => item.productId !== productIdToRemove);
    }

    // Salva o pedido no Salesforce
    handleSaveOrder() {
        this.isLoading = true;

        if (!this.recordId) {
            this.showToast('Erro', 'Este componente deve estar na página de uma Conta.', 'error');
            this.isLoading = false;
            return;
        }

        const params = {
            accountId: this.recordId,
            items: this.cartItems
        };

        createOrder(params)
            .then(orderId => {
                // Cria a URL para redirecionamento
                const orderUrl = `/lightning/r/Order/${orderId}/view`;

                this.showToast(
                    'Sucesso', 
                    'Pedido {0} criado com sucesso! Clique para abrir.', 
                    'success',
                    [
                        {
                            url: orderUrl,
                            label: 'Ver Pedido'
                        }
                    ]
                );
                
                // Limpa o carrinho
                this.cartItems = [];
                this.convertedTotal = null;
            })
            .catch(error => {
                console.error(error);
                let msg = error.body ? error.body.message : error.message;
                this.showToast('Erro', msg, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    // Converte Moeda usando a API Externa
handleCurrencyConvert(event) {
        // Agora o value do botão virá como 'BRL' ou 'EUR'
        const targetCurrency = event.target.value; 
        this.selectedCurrency = targetCurrency;
        this.isLoading = true;

        // Chamamos o Apex passando a moeda ALVO
        getCurrencyRate({ targetCurrency: targetCurrency })
            .then(rate => {
                this.exchangeRate = rate;

                // Total atual em Dólares (Soma simples)
                const totalUSD = this.cartItems.reduce((acc, item) => acc + (item.quantity * item.unitPrice), 0);
                
                if (rate > 0) {
                    // CORREÇÃO MATEMÁTICA: Multiplicação
                    // Se 1 USD = 5 BRL, então 100 USD = 500 BRL.
                    const convertedValue = totalUSD * rate;

                    // Formata para a moeda de destino
                    // 'pt-BR' para BRL, 'en-EU' (ou de-DE) para EUR
                    const locale = targetCurrency === 'BRL' ? 'pt-BR' : 'de-DE';

                    this.convertedTotal = new Intl.NumberFormat(locale, {
                        style: 'currency',
                        currency: targetCurrency,
                        minimumFractionDigits: 2
                    }).format(convertedValue);
                }
            })
            .catch(error => {
                this.showToast('Erro', 'Falha ao converter moeda.', 'error');
                console.error(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    // --- AUXILIARES ---
    showToast(title, message, variant, messageData = null) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            messageData: messageData
        });
        this.dispatchEvent(event);
    }
}