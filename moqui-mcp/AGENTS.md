# Moqui MCP Self-Guided Narrative Screens

## 🎯 Core Goal

Enable ANY AI/LLM model to autonomously navigate Moqui ERP and perform business tasks through **self-guided narrative screens** that provide:
- Clear description of current state
- Available actions with exact invocation examples
- Navigation guidance for related screens
- Contextual notes for constraints and next steps

The interface is **model-agnostic** - works with GPT, Claude, local models, or any other AI agent.

---

## 🏗️ Agent Runtime Architecture

Moqui MCP now includes an **Agent Runtime** that allows Moqui to host its own autonomous agents (via OpenAI-compatible APIs like VLLM, Ollama, etc.) that process background tasks.

### Architecture Overview

```
┌────────────────────────┐      ┌────────────────────────┐      ┌────────────────────────┐
│   Moqui Core           │      │   Agent Queue          │      │   Agent Runtime        │
│                        │      │                        │      │                        │
│ User Request           │ ---> │ SystemMessage (Pending)│ <--- │ Poll & Lock Message    │
│ (Trigger/Service)      │      │ Type: AgentTask        │      │                        │
└────────────────────────┘      └────────────────────────┘      │ 1. Build Prompt        │
                                                                │ 2. Call VLLM API       │
                                                                │ 3. Receive Tool Call   │
                                                                │ 4. Impersonate User    │
                                                                │ 5. Execute MCP Tool    │
                                                                │ 6. Save Result         │
                                                                └────────────────────────┘
```

### Key Components

1.  **Agent Client**: Connects to OpenAI-compatible endpoints (VLLM, OpenAI, etc.).
2.  **Agent Runner**: Orchestrates the conversation loop (Think → Act → Observe).
3.  **Secure Bridge**: Executes tools with user delegation (impersonation) to enforce RBAC.
4.  **ProductStoreAiConfig**: Configures AI models and endpoints per Product Store.

### Security Model

- **Authentication**: Agents authenticate as a dedicated service user (e.g., `AGENT_CLAUDE`).
- **Authorization**: Agents **impersonate** the requesting human user for specific tool executions.
    - If user `john.doe` cannot create products, the agent acting as `john.doe` cannot create products.
    - RBAC is fully enforced at the tool execution layer.

---

## 🧩 How Models Use the Interface

### Discovery Workflow
```
1. moqui_browse_screens(path="") → See available screens
2. moqui_get_screen_details(path="/PopCommerce/Catalog/Product") → Understand parameters
3. moqui_render_screen(path="/PopCommerce/Catalog/Product/FindProduct", parameters={name: "blue widget"}) → Execute with context
```

### Navigation Pattern
```
AI receives: "Find blue products in catalog"
→ Browse to /PopCommerce/Catalog
→ See subscreen: Product/FindProduct
→ uiNarrative.actions: "To search products, use moqui_render_screen(path='/PopCommerce/Catalog/Product/FindProduct', parameters={productName: 'blue'})"
→ AI executes exactly as guided
```

### Action Execution Pattern
```
AI receives: "Update PROD-001 price to $35.99"
→ Browse to /PopCommerce/Catalog/Product/EditPrices
→ uiNarrative.actions: "To update price, call with action='update', parameters={productId: 'PROD-001', price: 35.99}"
→ AI executes transition
→ Receives confirmation
→ Reports completion
```

---

## 🔧 Near-Term Fixes (Required for Generic Model Access)

COMPLETED ITEMS REMOVED

### Phase 3: Validation & Testing (PENDING)
- [ ] Server restart required to load changes
- [ ] Screen rendering tests run manually
- [ ] Transition execution tests run manually
- [ ] Path delimiter tests run manually
- [ ] Model-agnostic tests run (if models available)

---

## ✅ Validation: Generic Model Access

### Screen Rendering Tests (Requires server restart)
- [ ] Root screens (PopCommerce, SimpleScreens) render with uiNarrative
- [ ] Admin subscreens (Catalog, Order, Customer) accessible
- [ ] FindProduct screen renders with search form
- [ ] EditPrices screen renders with product data
- [ ] FindOrder screen renders with order data
- [ ] All screens have semantic state with forms/lists
- [ ] UI narratives are clear and actionable

### Transition Execution Tests (Requires server restart)
- [ ] Create actions work for all entity types
- [ ] Update actions work for all entity types
- [ ] Delete actions work where applicable
- [ ] Form submissions process parameters correctly
- [ ] Parameter validation catches missing fields
- [ ] Invalid parameters return helpful errors

### Path Delimiter Tests (Requires server restart)
- [ ] `/PopCommerce/PopCommerceAdmin/Catalog/Product` works
- [ ] Navigation links use `/` in output
- [ ] Error messages reference paths with `/`
- [ ] Documentation updated to use `/`

### Model Agnostic Tests (If possible)
- [ ] Screens work with any model (test with 2-3 if available)
- [ ] UI narrative provides sufficient guidance for autonomous action
- [ ] Errors are clear regardless of model choice
- [ ] No model-specific code or assumptions

### End-to-End Business Tasks (Requires server restart)
**Test with multiple models to ensure generic access:**
- [ ] Product search (any query pattern)
- [ ] Price update (any product, any price)
- [ ] Customer lookup (any customer identifier)
- [ ] Order creation (any customer, any product)
- [ ] Order status check (any order ID)
- [ ] Multi-step workflows (browse → execute → verify)

---

## 📊 Success Metrics

### Narrative Quality
- **Coverage**: 100% of screens should have uiNarrative
- **Clarity**: Models can understand current state from 50-80 word descriptions
- **Actionability**: Models have exact tool invocation examples for all actions
- **Navigation**: Models can navigate hierarchy independently

### Functional Coverage
- **Screen Access**: All documented screens should render successfully
- **Transition Types**: All action patterns (create, update, delete, submit) should work
- **Entity Coverage**: Should work across Product, Order, Customer, Inventory entities
- **Error Handling**: Clear, actionable error messages for all failure modes

### Model Agnosticism
- **Provider Independence**: Works with OpenAI, Anthropic, local models
- **Size Independence**: Effective for 7B models and 70B models
- **Input Flexibility**: Handles various natural language phrasings
- **Output Consistency**: Reliable responses regardless of model choice

---

## 🧪 Use Cases (Not Exhaustive)

### Human-in-the-Loop
- User: "Help me find products"
- Model: Screens for browsing, narrows to products, presents options
- User: Selects product, asks for price change
- Model: Executes price update, confirms
- User: Reviews and approves

### External AI Integration
- External system: "Create order for customer CUST-001: 5 units of PROD-002"
- HTTP API to Moqui MCP
- MCP: Executes order creation
- Returns: Order ID and confirmation
- External system: Confirms and updates records

### Manual Model Testing
- Developer: Runs model through MCP interface
- Model: Navigates screens, performs tasks
- Developer: Observes behavior, validates output
- Developer: Adjusts UI narrative or transition logic based on model struggles

---

## 🚀 Future Enhancements

Beyond core narrative screens:
- Multi-agent coordination via notifications
- Context retention across sessions
- Proactive suggestions
- Advanced workflow orchestration
- Agent that monitors notifications and executes tasks autonomously
