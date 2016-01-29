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

| Field     | Length | Type    |
|-----------|--------|---------|
| msgType   | 2      |         |
| side      | 1      |         |
| type      | 3      |         |
| volume    | 7      | NUMERIC |
| symbol    | 12     |         |
| price     | 8      | NUMERIC |
| clientId  | 16     |         |
| accountId | 16     |         |

### OC - Order Confirmation

| Field     | Length | Type    |
|-----------|--------|---------|
| msgType   | 2      |         |
| orderId   | 6      |         |
| side      | 1      |         |
| type      | 3      |         |
| volume    | 7      | NUMERIC |
| symbol    | 12     |         |
| price     | 8      | NUMERIC |
| clientId  | 16     |         |
| accountId | 16     |         |

### TR - Trade

| Field   | Length | Type    |
|---------|--------|---------|
| msgType | 2      |         |
| tradeId | 6      |         |
| orderid | 6      |         |
| volume  | 7      | NUMERIC |
| symbol  | 12     |         |
| price   | 8      | NUMERIC |

### RJ - Rejection

| Field         | Length | Type    | Description                   |
|---------------|--------|---------|-------------------------------|
| msgType       | 2      |         | Message type                  |
| clientId      | 16     |         | Client Id                     |
| rejectionCode | 3      | NUMERIC | Rejection Code                |
| text          | 48     |         | Text explaining the rejection |

### EN - Exchange News

| Field   | Length  | Type   |
|---------|---------|--------|
| msgType | 2       |        |
| textLen | 4       |        |
| text    | textLen | VARLEN |
| source  | 16      |        |

### BO - Best Bid and Offer

| Field            | Length           | Type      |
|------------------|------------------|-----------|
| MsgType          | 2                |           |
| Symbol           | 12               |           |
| Number of levels | 1                | NUMERIC   |
| Levels           | Number of levels | REPEATING |
| Bid Volume       | 7                | NUMERIC   |
| Bid Price        | 8                | NUMERIC   |
| Bid Orders       | 5                | NUMERIC   |
| Offer Volume     | 7                | NUMERIC   |
| Offer Price      | 8                | NUMERIC   |
| Offer Orders     | 5                | NUMERIC   |

### LO - Lough Out

\*\*experimental\*\*

| Field   | Length | Type |
|---------|--------|------|
| msgType | 2      |      |

Appendix
--------

Blah blah blah.
