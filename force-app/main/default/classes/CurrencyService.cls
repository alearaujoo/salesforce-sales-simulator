public with sharing class CurrencyService {

    @AuraEnabled
    public static Decimal getCurrencyRate(String targetCurrency) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        // MUDANÇA ARQUITETURAL:
        // A Base agora é USD (Org). O Alvo é dinâmico.
        // A API AwesomeAPI usa o formato: /last/MOEDA_ORIGEM-MOEDA_DESTINO
        String pair = 'USD-' + targetCurrency; 
        String endpoint = 'https://economia.awesomeapi.com.br/last/' + pair;
        
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setTimeout(10000);
        
        try {
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                
                // A chave retornada é a concatenação sem hífen (ex: USDEUR)
                String key = 'USD' + targetCurrency;
                
                if (results.containsKey(key)) {
                    Map<String, Object> currencyData = (Map<String, Object>) results.get(key);
                    String bidValue = (String) currencyData.get('bid');
                    return Decimal.valueOf(bidValue);
                }
            }
            // Se falhar silenciosamente ou chave não existir
            return 0;
            
        } catch (Exception e) {
            System.debug('Erro de Integração: ' + e.getMessage());
            return 0;
        }
    }
}