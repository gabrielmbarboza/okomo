# Okomo - Projeto Rails API com DDD Completo

## ✅ Configurações Finalizadas

### Stack Implementado
- **Ruby on Rails 8.1.3** (API-only)
- **PostgreSQL 16** com UUID
- **Redis 7** para background jobs
- **Docker & Docker Compose**
- **Sidekiq** configurado para uso futuro

### Arquitetura DDD
Estrutura de domínios criada em `app/domains/`:
- `catalog/` - Catálogo de produtos
- `orders/` - Gestão de pedidos  
- `payments/` - Processamento de pagamentos
- `shipping/` - Logística e envio
- `inventory/` - Controle de estoque

Cada domínio contém:
- `entities/` - Objetos de domínio (POROs)
- `services/` - Lógica de negócio
- `value_objects/` - Objetos de valor
- `repositories/` - Acesso a dados

### Configurações Técnicas

#### Docker
- Multi-stage build com usuário não-root
- Suporte a UID/GID para permissões corretas
- Health checks para todos os serviços
- Volumes persistentes para dados

#### Database
- PostgreSQL com extensão `pgcrypto` habilitada
- UUID configurado como primary key padrão
- Migrations base criadas
- Variáveis de ambiente para conexão

#### API
- CORS configurado para desenvolvimento
- Timezone: America/Sao_Paulo
- Locale: pt-BR com fallback para en
- Logging estruturado para stdout
- Gems essenciais instaladas

## 🚀 Como Usar

### Iniciar o projeto
```bash
docker-compose up -d
```

### Executar migrations
```bash
docker-compose exec app rails db:migrate
```

### Acessar a API
- URL: http://localhost:3000
- PostgreSQL: localhost:5433
- Redis: localhost:6380

### Criar novo modelo com UUID
```bash
docker-compose exec app rails g model Product name:string description:text --primary_key_type=uuid
```

## 📁 Estrutura de Arquivos Principais

```
okomo/
├── app/
│   ├── domains/           # Arquitetura DDD
│   │   ├── catalog/
│   │   ├── orders/
│   │   ├── payments/
│   │   ├── shipping/
│   │   └── inventory/
│   ├── controllers/
│   └── models/
├── config/
│   ├── database.yml       # PostgreSQL configurado
│   ├── application.rb     # Configurações DDD e UUID
│   └── initializers/
│       ├── cors.rb        # CORS configurado
│       └── uuid_primary_key.rb
├── docker-compose.yml     # Orquestração completa
├── Dockerfile            # Build otimizado
├── Gemfile               # Dependências essenciais
└── .env                  # Variáveis de ambiente
```

## 🎯 Próximos Passos

O projeto está pronto para desenvolvimento:

1. **Criar entidades de domínio** em `app/domains/*/entities/`
2. **Implementar serviços de negócio** em `app/domains/*/services/`
3. **Criar controllers** que orquestram requisições
4. **Implementar Sidekiq workers** para background jobs
5. **Adicionar testes** para a arquitetura DDD

## 🔧 Comandos Úteis

```bash
# Ver status dos containers
docker-compose ps

# Logs da aplicação
docker-compose logs -f app

# Acessar console Rails
docker-compose exec app rails c

# Criar nova migration
docker-compose exec app rails g migration AddFieldsToTable

# Rodar testes
docker-compose exec app rails test
```

---
**Projeto Okomo** - Arquitetura escalável com Rails 8 API + DDD + Docker ✨
