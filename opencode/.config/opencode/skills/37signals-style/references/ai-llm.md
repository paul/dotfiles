# AI/LLM Integration Patterns

The useful parts here are around result objects, tool boundaries, and cost tracking.

## Keep

- track provider costs in integer units such as microcents
- use small result objects for controller responses
- treat tools as boundary objects that gather and format data for the model

## Compatible Adjustments

- no STI command trees
- no inheritance-heavy command architecture
- represent durable AI workflows with plain objects, transactions, and explicit records

## Recommended Shape

- parsing and execution live in plain objects or transactions
- persisted AI records store inputs, outputs, and costs explicitly
- controllers interpret lightweight result objects instead of coupling domain logic to HTTP
