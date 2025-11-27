# Salesforce Sales Simulator (LWC + Apex)

## 1. Visão Geral da Solução
O Simulador de Vendas é uma solução SPA (Single Page Application) desenvolvida para acelerar o processo de criação de pedidos.
Diferente do fluxo padrão, esta ferramenta permite que vendedores pesquisem produtos, montem um carrinho virtual e consolidem o pedido em uma única tela, eliminando múltiplos cliques e reduzindo o tempo de atendimento (TMA).

## 2. Arquitetura Técnica

### Frontend (Lightning Web Components)
A solução utiliza o padrão de composição "Pai-Filho" para gerenciamento de estado:

* **`salesSimulator` (Orquestrador):** Gerencia o estado do carrinho (Array em memória), realiza cálculos de totais em tempo real usando `Intl.NumberFormat` e coordena a gravação dos dados.
* **`productSearch` (Apresentação):** Componente desacoplado responsável pela busca de produtos via Wire Service e notificação de seleção via Custom Events.

### Backend (Apex Controller)
A classe `SalesSimulatorController` atua como a camada de serviço segura:

* **Padrão DTO:** Utiliza uma *Inner Class* para tipar os dados recebidos do Frontend.
* **Controle Transacional:** Implementa `Savepoint` e `Rollback` para garantir a atomicidade. Se a criação de um item falhar, o pedido inteiro é revertido.
* **Segurança:** Executa em modo `with sharing` e valida permissões de acesso aos dados.

## 3. Instalação
Para realizar o deploy deste projeto em uma Org Salesforce:

1.  Clone o repositório.
2.  Execute: `sf project deploy start --target-org SeuAlias`