@RestResource(urlMapping='/LeadIngestion/*')
global with sharing class LeadIngestionService {
  /**
   * @description DTO para entrada de dados.
   * @description Data Transder Object (DTO) for input data.
   */
  global class LeadRequest {
    public String externalId;
    public String companyName;
    public String email;
    public String lastName;
    public decimal annualRevenue;
  }

  /**
   * @description DTO para resposta da API
   * @description API Reponse API
   */
  global class LeadResponse {
    public Boolean success;
    public String message;
    public String salesforceId;
  }

  @HttpPost
  global static LeadResponse createIncomingLead() {
    LeadResponse resp = new LeadResponse();

    try {
      // 1. Ler o corpo da requisição (O JSON que enviaram)
      // 1. Read the request body (The JSON that was sent)
      RestRequest req = RestContext.request;
      String jsonBody = req.requestBody.toString();

      // 2. Desserializar o JSON para o Objeto Apex
      // 2. Deserialize JSON into the Apex Object
      LeadRequest incomingData = (LeadRequest) JSON.deserialize(
        jsonBody,
        LeadRequest.class
      );

      // 3. Lógica de Deduplicação (Evitar duplicidade pelo e-mail)
      // 3. Deduplication Logic (Avoid duplicates by email)
      List<Lead> existingLeads = [
        SELECT Id
        FROM Lead
        WHERE Email = :incomingData.email
        LIMIT 1
      ];

      Lead leadToUpsert = new Lead();
      if (!existingLeads.isEmpty()) {
        leadToUpsert.Id = existingLeads[0].Id; //Atualiza
      }

      // 4. Mapeamento de Dados
      // 4. Data Mapping
      leadToUpsert.LastName = incomingData.lastName;
      leadToUpsert.Company = incomingData.companyName;
      leadToUpsert.Email = incomingData.email;
      leadToUpsert.AnnualRevenue = incomingData.annualRevenue;
      leadToUpsert.LeadSource = 'External ERP API'; //Rastreabilidade

      // Executa a operação de escrita (Criar ou Atualizar)
      // Executes the write operation (Create or Update)
      upsert leadToUpsert;

      // 5. Montar resposta de sucesso
      // 5. Build success response
      resp.success = true;
      resp.message = 'Lead processed successfully.';
      resp.salesforceId = leadToUpsert.Id;
    } catch (Exception e) {
      // Tratamento de Erro e Retorno 500
      // Error Handling and 500 Response
      System.debug('Erro: ' + e.getMessage());
      resp.success = false;
      resp.message = 'Erro crítico: ' + e.getMessage();
      RestContext.response.statusCode = 500; //Internal Server Error
    }
    return resp;
  }
}
