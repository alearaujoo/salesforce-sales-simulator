import pandas as pd 

# 1. EXTRACT
raw_data = {
    'external_id': ['ERP_001', 'ERP_002', 'ERP_003'],
    'name': ['  Elon Musk ', 'jeff bezos', 'Bill GATES'], 
    'email': ['ceo@tesla.com', 'ceo@amazon.com', 'bill@microsoft.com'],
    'revenue': [5000000, 4000000, 3500000]
}

print("--- 1. DADOS ORIGINAIS (SUJOS) ---")
df = pd.DataFrame(raw_data)
print(df)

# 2. TRANSFORM
print("\n--- 2. PROCESSANDO LIMPEZA... ---")
df['name'] = df['name'].str.strip().str.title()
high_value_clients = df[df['revenue'] > 4000000]

# 3. LOAD
print("\n--- 3. DADOS LIMPOS E FILTRADOS ---")
print(high_value_clients)