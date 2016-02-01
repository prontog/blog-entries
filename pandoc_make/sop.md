Simple Order Protocol (sop), an imaginary protocol.
===================================================

Introduction
------------

SOP is a simple, text protocol for an imaginary stock exchange. Use it to place simple orders and make simple trades.

All message types follow the format HEADER|PAYLOAD|TRAILER (note that '|' is not included in the protocol).

Header
------

The HEADER is very simple:

| Field | Length | Type    | Description                                     |
|-------|--------|---------|-------------------------------------------------|
| SOH   | 1      | STRING  | Start of header.                                |
| LEN   | 3      | NUMERIC | Length of the payload (i.e. no header/trailer). |

Trailer
-------

The TRAILER is even simpler:

| Field | Length | Type   | Description  |
|-------|--------|--------|--------------|
| ETX   | 1      | STRING | End of text. |

Message types
-------------

The message types are:

| Type | Description        |
|------|--------------------|
| NO   | New Order          |
| OC   | Order Confirmation |
| TR   | Trade              |
| RJ   | Rejection          |
| EN   | Exchange News      |
| BO   | Best Bid and Offer |

### NO - New Order

| Field     | Length | Type    | Description                                                 |
|-----------|--------|---------|-------------------------------------------------------------|
| msgType   | 2      |         | Defines message type ALWAYS FIRST FIELD IN MESSAGE PAYLOAD. |
| side      | 1      |         | Side of order. B for buy, S for sell.                       |
| type      | 3      |         | Order type. LMT for limit, MKT for market.                  |
| volume    | 7      | NUMERIC | Number of shares.                                           |
| symbol    | 12     |         | Ticker symbol.                                              |
| price     | 8      | NUMERIC | Price per unit of quantity (e.g. per share)                 |
| clientId  | 16     |         | Unique identifier for Order as assigned by the client.      |
| accountId | 16     |         | Identifier for the account of be used for clearance.        |

### OC - Order Confirmation

| Field     | Length | Type    | Description                                                 |
|-----------|--------|---------|-------------------------------------------------------------|
| msgType   | 2      |         | Defines message type ALWAYS FIRST FIELD IN MESSAGE PAYLOAD. |
| orderId   | 6      |         | Unique identifier for Order as assigned by the exchange.    |
| side      | 1      |         | Side of order. B for buy, S for sell.                       |
| type      | 3      |         | Order type. LMT for limit, MKT for market.                  |
| volume    | 7      | NUMERIC | Number of shares.                                           |
| symbol    | 12     |         | Ticker symbol.                                              |
| price     | 8      | NUMERIC | Price per unit of quantity (e.g. per share)                 |
| clientId  | 16     |         | Unique identifier for Order as assigned by the client.      |
| accountId | 16     |         | Identifier for the account of be used for clearance.        |

### TR - Trade

| Field   | Length | Type    | Description                                                 |
|---------|--------|---------|-------------------------------------------------------------|
| msgType | 2      |         | Defines message type ALWAYS FIRST FIELD IN MESSAGE PAYLOAD. |
| tradeId | 6      |         | Unique identifier for Trade as assigned by the exchange.    |
| orderid | 6      |         | Unique identifier for Order as assigned by the exchange.    |
| volume  | 7      | NUMERIC | Number of shares.                                           |
| symbol  | 12     |         | Ticker symbol.                                              |
| price   | 8      | NUMERIC | Price per unit of quantity (e.g. per share)                 |

### RJ - Rejection

| Field         | Length | Type    | Description                                                 |
|---------------|--------|---------|-------------------------------------------------------------|
| msgType       | 2      |         | Defines message type ALWAYS FIRST FIELD IN MESSAGE PAYLOAD. |
| clientId      | 16     |         | Client Id                                                   |
| rejectionCode | 3      | NUMERIC | Rejection Code                                              |
| text          | 48     |         | Text explaining the rejection                               |

### EN - Exchange News

| Field   | Length  | Type   | Description                                                 |
|---------|---------|--------|-------------------------------------------------------------|
| msgType | 2       |        | Defines message type ALWAYS FIRST FIELD IN MESSAGE PAYLOAD. |
| textLen | 4       |        | Length of text field.                                       |
| text    | textLen | VARLEN | Free format text string.                                    |
| source  | 16      |        | Source of the news.                                         |

### BO - Best Bid and Offer

| Field            | Length           | Type      | Description                                                 |
|------------------|------------------|-----------|-------------------------------------------------------------|
| MsgType          | 2                |           | Defines message type ALWAYS FIRST FIELD IN MESSAGE PAYLOAD. |
| Symbol           | 12               |           | Ticker symbol.                                              |
| Number of levels | 1                | NUMERIC   | Number of BBO levels                                        |
| Levels           | Number of levels | REPEATING |                                                             |
| Bid Volume       | 7                | NUMERIC   | Bid number of shares.                                       |
| Bid Price        | 8                | NUMERIC   | Bid price per unit of quantity (e.g. per share)             |
| Bid Orders       | 5                | NUMERIC   | Bid number of orders                                        |
| Offer Volume     | 7                | NUMERIC   | Offer number of shares.                                     |
| Offer Price      | 8                | NUMERIC   | Offer price per unit of quantity (e.g. per share)           |
| Offer Orders     | 5                | NUMERIC   | Offer number of orders                                      |

### LO - Lough Out

\*\*experimental\*\*

| Field   | Length | Type | Description                                                 |
|---------|--------|------|-------------------------------------------------------------|
| msgType | 2      |      | Defines message type ALWAYS FIRST FIELD IN MESSAGE PAYLOAD. |

Appendix
--------

Blah blah blah.
