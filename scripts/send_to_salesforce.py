import requests
import json
import os
from dotenv import load_dotenv

# Carrega as variáveis do arquivo .env
load_dotenv()

# --- SUAS CREDENCIAIS (SEGURAS) ---
CLIENT_ID = os.getenv('SALESFORCE_CLIENT_ID')
CLIENT_SECRET = os.getenv('SALESFORCE_CLIENT_SECRET')
USERNAME = os.getenv('SALESFORCE_USERNAME')
PASSWORD = os.getenv('SALESFORCE_PASSWORD')

# --- CONFIGURAÇÕES TÉCNICAS ---
# URL de Login (Padrão para Developer Edition e Production)
LOGIN_URL = 'https://login.salesforce.com/services/oauth2/token'

# O endereço da sua API Apex (definido no @RestResource)
APEX_ENDPOINT = '/services/apexrest/LeadIngestion/'

def get_salesforce_token():
    """Faz o login e pega o crachá de acesso (Token)"""
    payload = {
        'grant_type': 'password',
        'client_id': CLIENT_ID,
        'client_secret': CLIENT_SECRET,
        'username': USERNAME,
        'password': PASSWORD
    }
    
    print("🔄 Tentando logar no Salesforce...")
    try:
        response = requests.post(LOGIN_URL, data=payload)
        response_data = response.json()
        
        if response.status_code == 200:
            print("✅ Login realizado com sucesso!")
            return response_data
        else:
            print(f"❌ Erro no login: {response_data.get('error_description', response.text)}")
            return None
    except Exception as e:
        print(f"❌ Erro de conexão: {e}")
        return None

def send_lead_to_apex(access_token, instance_url, lead_data):
    """Envia o JSON do Lead para a API Apex"""
    
    # Cabeçalho de autorização (O crachá)
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    }
    
    # URL completa (https://sua-org... + /services/apexrest/LeadIngestion/)
    full_url = instance_url + APEX_ENDPOINT
    
    print(f"\n📤 Enviando Lead: {lead_data['companyName']}...")
    
    try:
        response = requests.post(full_url, headers=headers, json=lead_data)
        
        if response.status_code == 200:
            print(f"🚀 SUCESSO! Resposta do Salesforce:")
            print(json.dumps(response.json(), indent=4))
        else:
            print(f"⚠️ Falha na API: {response.status_code}")
            print(response.text)
            
    except Exception as e:
        print(f"❌ Erro ao enviar: {e}")

# --- EXECUÇÃO DO ROBÔ ---
if __name__ == "__main__":
    # 1. Autenticar
    auth_response = get_salesforce_token()
    
    if auth_response:
        # Pega o token e o endereço da sua Org (instance_url)
        token = auth_response['access_token']
        instance_url = auth_response['instance_url']
        
        # 2. Dados para Enviar (Simulando o "Elon Musk" limpo)
        # Note que usamos o externalId para garantir o Upsert
        robot_lead = {
            "externalId": "PY_ROBOT_2025",
            "companyName": "SpaceX Python Integration",
            "email": "elon.python@spacex.com",
            "lastName": "Musk (Via Script)",
            "annualRevenue": 88000000
        }
        
        # 3. Enviar para o Apex
        send_lead_to_apex(token, instance_url, robot_lead)