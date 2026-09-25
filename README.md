## Rules for Low-Latency National Stock Exchange Non Neat Front End Protocol in SystemVerilog

**1. Parse on the fly, never store-and-forward**
NNF messages are packed, big-endian structs with every field at a fixed offset. Decode the Transaction Code in the first bytes and use it to pick the offset map. Then pull out each field as its bytes arrive, so the result is ready on the last byte and not one full message later. Describe each layout as a `typedef struct packed`, so the offsets come straight from the spec and aren't hand-counted.

**2. Keep exchange data in its native form, with no floating point in the fast path**
Order numbers arrive as 8-byte DOUBLEs: treat them as opaque 64-bit keys and match them bit for bit. Prices are integers in paise. Leaving both as raw bits removes conversion logic and rounding risk, and keeps the timing path short.

**3. Check integrity in parallel, not in series**
Each packet has a wrapper with Length, Sequence Number and an MD5 checksum. Run the sequence and checksum logic alongside the parser, and combine the result into `valid` at end-of-message. The datapath should never stall waiting for it. On the transmit side, pipeline the MD5 so it doesn't sit on the critical path.

**4. Enforce the session rules in hardware**
The session has rules: the sign-on sequence, heartbeats, and per-user message-rate (throttle) limits. Build them into the RTL, along with pre-trade risk checks, so the fast path cannot send anything that breaks exchange limits. A rejected or disconnected session costs far more than a few nanoseconds.

**5. Fixed, measurable latency, proven by verification**
Write fully synchronous pipelines (`always_ff`, no latches, no variable-length loops) so each message type has a fixed cycle count. Check correctness with SVA assertions on field offsets and valid/last handshakes. Replay captured or simulated exchange traffic through the design and measure latency cycle by cycle.
