# Project 5: Building an MCP Server for Exploring Human STR Variation

## Background

**Short tandem repeats (STRs)** are DNA sequences in which a short motif is repeated several times. Repeat lengths can vary between individuals. Exploring this variation and its genomic context can help us investigate human genetic diversity and cancer biology.

The **WebSTR REST API** provides access to genes, STR locations and characteristics, population variation records, and colorectal cancer variation data. A REST API is usually queried through URLs and parameters. The **Model Context Protocol (MCP)** allows an AI assistant to discover and call tools provided by a server.

In this project, you will build an MCP server that translates tool calls into WebSTR API requests. You will then connect it to an MCP-compatible AI client and evaluate whether the assistant can retrieve and explain biological information correctly.

## Research questions

1. Can an AI assistant use your MCP tools to answer questions about STRs associated with a gene or genomic region?
2. How accurately does it select tools, connect results across queries, and report the retrieved biological information?
3. What happens when a question contains an unknown identifier, returns no records, or cannot be answered from the available data?

## Tasks

1. **Read the documentation.** Explore the WebSTR API and learn how MCP servers expose tools. Check the API's identifiers, response fields, genome assembly, and coordinate conventions. Record any information that is unclear and clarify it before interpreting results.
2. **Explore the API directly.** Make example requests for genes, associated repeats, repeat details, and population records. Inspect the responses and choose genes or regions with useful data for your demonstration.
3. **Design and implement four MCP tools.** Use the core tools below as a starting point. Define clear names, descriptions, input schemas, and structured results. Explain any changes to the proposed design.
4. **Handle errors and large responses.** Validate inputs, set request timeouts, and distinguish invalid input, no matching records, and an unavailable API. Require a gene or region for repeat searches. Bound result sizes and clearly state when results have been truncated; do not silently present partial results as complete.
5. **Connect an AI client.** Demonstrate that an MCP-compatible client can discover and call your tools. Record the client, model, SDK version, and configuration needed to reproduce your setup. A local server is sufficient.
6. **Demonstrate two biological use cases.** Include at least one workflow that requires several tool calls, such as resolving a gene, finding its STRs, and retrieving population records for a selected repeat. Explain what the results support and what they do not establish.
7. **Evaluate correctness.** Prepare a benchmark of 10–15 questions and expected results obtained through direct API queries. Evaluate the assistant using the procedure below.
8. **Interpret your findings.** Discuss successful workflows, failure cases, limitations of the data and documentation, and improvements to your tool design.

## Data and API access

No expression matrices or histology images are required. Retrieve data from WebSTR:

- [WebSTR API documentation](https://webstr-api.lsfm.zhaw.ch/docs)
- [WebSTR OpenAPI specification](https://webstr-api.lsfm.zhaw.ch/openapi.json)

Save the OpenAPI specification used, record retrieval dates, and retain the direct-query responses used for evaluation so that your results can be checked if the service changes. Avoid repeatedly downloading large datasets; reuse saved responses where appropriate.

### Core tools

| Suggested tool | WebSTR endpoint | Purpose |
| --- | --- | --- |
| `find_genes` | `GET /gene/` | Find genes by gene symbol, Ensembl ID, or genomic region and return their identifiers and coordinates. |
| `find_repeats` | `GET /repeats` | Retrieve STRs associated with a gene or genomic region. |
| `get_repeat_details` | `GET /repeatinfo/` | Retrieve information for a selected integer `repeat_id`, including its motif and genomic location. |
| `get_population_frequencies` | `GET /allfreqs/` | Retrieve the available population-specific records for a selected `repeat_id`. |

**Check the actual parameter names.** In the current schema, `/gene/` spells its region parameter `reqion_query`, while `/repeats` uses `region_query`. Your MCP tools can expose a consistent name and translate it into the parameter expected by each endpoint.

Preserve gene and repeat identifiers, relevant field names, and query provenance in tool results. Confirm the meaning of fields such as `frequency`, `het`, and `n_effective` before interpreting them. If their definitions cannot be established, report that limitation rather than inventing a biological explanation. Do not infer disease risk from population variation alone.

## Evaluation workflow

### Step 1 — Define the benchmark

Include questions covering:

- A single gene lookup.
- Finding repeats for a gene or region.
- Retrieving details and population records for an existing repeat.
- A multi-step biological question requiring information from several endpoints.
- An unknown gene, an invalid repeat identifier, and a query with no matching records.
- A request whose answer is not available from the exposed tools.

Choose concrete identifiers after checking the API. For each question, save the direct API request, response, and the facts expected in a correct answer. Distinguish an empty response from a failed request.

### Step 2 — Check the server and the assistant separately

First verify that the MCP tools return results consistent with direct API calls. Include checks for parameter translation, invalid input, empty results, timeouts, and response truncation. Use saved or simulated responses for failures that cannot be reliably triggered against the live API.

Then run the benchmark through the AI client. Record the question, tool calls and arguments, final answer, model version, and date. Repeat a small subset of multi-step questions to investigate whether behavior is consistent.

### Step 3 — Report results

For each question, assess:

| Criterion | What to check |
| --- | --- |
| Tool selection | Did the assistant choose suitable tools and valid arguments? |
| Query chaining | Did it carry the correct gene or repeat identifier between calls? |
| Factual accuracy | Do the identifiers, numerical values, and summaries agree with the saved API responses? |
| Biological interpretation | Are conclusions supported by the returned data and documented field meanings? |
| Handling limitations | Does it acknowledge missing data, failed requests, unavailable information, or truncated results? |

Report the number of questions answered correctly out of the total and summarize the main error types. Define your scoring rules before evaluating the answers. Separate server implementation errors from mistakes made by the assistant.

## Expected outputs

- Working MCP server source code with dependency versions and setup instructions.
- Example client configuration and a short guide for running the demonstration. Keep credentials out of submitted files.
- Two documented biological use cases, including queries, returned identifiers, and interpretation.
- Benchmark questions, direct-query reference results, assistant outputs, and an evaluation table.
- A written report following the [course requirements](../../README.md), including a **Statement of AI Use** describing when and how you used AI to develop the server and evaluate its behavior.

A graphical interface, public deployment, model training, and implementation of every API endpoint are **not required**.

## Optional extensions

After completing the core workflow, choose one extension if time allows:

- Add colorectal cancer STR variation queries using `/variations/`.
- Explore the repeat-length/gene-expression association records from `/crc_expr_repeatlen_corr/`, after clarifying the statistical definitions and dataset context.
- Compare two tool designs or descriptions using the same benchmark and model.
- Add a reproducible plot or table summarizing a selected gene's STRs or population records.

## Documentation and tutorials

- [MCP: Build an MCP server](https://modelcontextprotocol.io/docs/develop/build-server)
- [Official MCP Python SDK](https://github.com/modelcontextprotocol/python-sdk)
- [WebSTR API documentation](https://webstr-api.lsfm.zhaw.ch/docs)

Use the documentation matching your installed SDK version. Python is a suitable choice, but another language with an MCP SDK is acceptable. You need an MCP-compatible AI client for the assistant evaluation; discuss available access with the instructor before choosing a client that requires payment.

**Questions or unclear API fields?** Contact me at [xiaf@zhaw.ch](mailto:xiaf@zhaw.ch).
