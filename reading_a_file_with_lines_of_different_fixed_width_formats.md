During the last couple of years, I've been relearning statistics through various online courses most of which had assignments in the [R programming language](https://www.r-project.org/about.html). Soon enough I grew fond of the simplicity of the language, of its powerful interpreter, of its documentation and base library with its many useful functions for importing, analyzing, plotting and exporting data.

### Why (create a tool)

As I was exploring the import functions (most of them are named read.*XXX*) I fell across [read.fwf](https://stat.ethz.ch/R-manual/R-devel/library/utils/html/read.fwf.html) that reads files with lines of fixed width format. You just pass it a filename and two vectors, one with the name of the columns and another with the size (in characters) of its column. It returns a data.frame with each line split into columns. Nice! In the company where I work we maintain several text protocols for inter-process communication, and one of them is fixed width. Yoo-Hoo, I could read a log file into R and fool around with it. But wait, I forgot, these logs are more complicated. Each line is fixed width, but the protocol includes different message types each one with different formatting. This means that the log file has lines of different fixed width format and *read.fwf* cannot handle such a file. What I needed was a function capable of handling multiple fixed width formats in a single file. Searching in R's *base* package, [CRAN](https://cran.r-project.org), Github and Google didn't result anything useful.

### How

I decided to create it myself and try building it around *read.fwf* since the base package developers have made such a good job with it.

#### Design

After some thought, I arrived at the following design:

1.  Split the file according to message type.
2.  Read each new file with *read.fwf*.

So instead of passing the *name* and *width* vectors I would pass a *list* of name and width of vectors with each pair specifying a message type. On success, the function would return a *list* of data.frames. Here's the signature of the function:

[read.multi.fwf](http://finzi.psych.upenn.edu/library/multifwf/html/read.multi.fwf.html)(file, multi.specs, select, header = FALSE, sep = "", skip = 0, n = -1, buffersize = 2000, ...)

Before starting with the implementation, I studied *read.fwf* thoroughly and decided to follow its basic structure and argument handling.

#### Implementation

The first implementation ([v0.1](https://github.com/prontog/multifwf/releases/tag/v0.1)) was buggy because of an optimization during the handling of the temp files (from step 1 of the design). To write to these files I use the *cat* function for each line read from the whole file. Instead of calling *cat* with the temp filename as parameter *file*, I used *connection objects* (think of it as file descriptors). This meant that I had to use the *open* function to open each temp file, use the *connection* and close it (using the *close* function) before returning. This might sound simple but in reality it wasn't. Although the function returned the correct result, some files were left opened (and were eventually closed by R) while others were closed multiple times (throwing exceptions). After trying to debug this for a while, I gave up and used *cat* with filenames instead of file handles, which solved the problem. In hidsight, this was a classic case of premature optimization. On the downside, I measured, a performance drop of around 20% which, to be honest, is fine by me.

> Did you know: That you can see the source of an R function simply by typing its name on the R console?

### How to use it

The function is available on CRAN in the package [multifwf](https://cran.r-project.org/web/packages/multifwf/index.html) and the source code in [Github](https://github.com/prontog/multifwf).

Here's an example on how to use **read.multi.fwf**:

``` r
library(multifwf)

# Create a temp file with a few lines from a SOP (Simple Order Protocol,
# an imganinary protocol) log file.
ff <- tempfile()
cat(file = ff, 
    '10:15:03:279NOSLMT0000666    EVILCORP00010.77SomeClientId    SomeAccountId   ',
    '10:15:03:793OC000001BLMT0000666    EVILCORP00010.77SomeClientId    SomeAccountId   ',
    '10:17:45:153NOBLMT0000666    EVILCORP00001.10AnotherClientId AnotherAccountId',
    '10:17:45:487RJAnotherClientId 004price out of range                              ',
    '10:18:28:045NOBLMT0000666    EVILCORP00011.00AnotherClientId AnotherAccountId',
    '10:18:28:472OC000002BLMT0000666    EVILCORP00011.00AnotherClientId AnotherAccountId',
    '10:18:28:642TR0000010000010000666    EVILCORP00010.77',
    '10:18:28:687TR0000010000020000666    EVILCORP00010.77', 
    sep = '\n')

# Create a list of specs. Each item contains the specification for
# each message type of this simple protocol.
specs <- list()
specs[['newOrder']] <- data.frame(
    widths = c(12, 2, 1, 3, 7, 12, 8, 16, 16), 
    col.names = c('timestamp', 'msgType', 'side', 'type', 'volume', 
                  'symbol', 'price', 'clientId', 'accountId'))
specs[['orderConf']] <- data.frame(
    widths = c(12, 2, 6, 1, 3, 7, 12, 8, 16, 16), 
    col.names = c('timestamp', 'msgType', 'orderId', 'side', 'type', 
                  'volume', 'symbol', 'price', 'clientId', 'accountId'))

specs[['rejection']] <- data.frame(
    widths = c(12, 2, 16, 3, 48), 
    col.names = c('timestamp', 'msgType', 'clientId', 
                  'rejectionCode', 'text'))

specs[['trade']] <- data.frame(
    widths = c(12, 2, 6, 6, 7, 12, 8), 
    col.names = c('timestamp', 'msgType', 'tradeId', 'orderId', 
                  'volume', 'symbol', 'price'))

# The selector function is responsible for identifying the message type 
# of a line.
myselector <- function(line, specs) {
    s <- substr(line, 13, 14)
    spec_name = ''
    if (s == 'NO')
        spec_name = 'newOrder'
    else if (s == 'OC')
        spec_name = 'orderConf'
    else if (s == 'TR')
        spec_name = 'trade'
    else if (s == 'RJ')
        spec_name = 'rejection'

    spec_name
}

read.multi.fwf(ff, multi.specs = specs, select = myselector)
#> $newOrder
#>      timestamp msgType side type volume       symbol price
#> 1 10:15:03:279      NO    S  LMT    666     EVILCORP 10.77
#> 2 10:17:45:153      NO    B  LMT    666     EVILCORP  1.10
#> 3 10:18:28:045      NO    B  LMT    666     EVILCORP 11.00
#>           clientId        accountId
#> 1 SomeClientId     SomeAccountId   
#> 2 AnotherClientId  AnotherAccountId
#> 3 AnotherClientId  AnotherAccountId
#> 
#> $orderConf
#>      timestamp msgType orderId side type volume       symbol price
#> 1 10:15:03:793      OC       1    B  LMT    666     EVILCORP 10.77
#> 2 10:18:28:472      OC       2    B  LMT    666     EVILCORP 11.00
#>           clientId        accountId
#> 1 SomeClientId     SomeAccountId   
#> 2 AnotherClientId  AnotherAccountId
#> 
#> $rejection
#>      timestamp msgType         clientId rejectionCode
#> 1 10:17:45:487      RJ AnotherClientId              4
#>                                               text
#> 1 price out of range                              
#> 
#> $trade
#>      timestamp msgType tradeId orderId volume       symbol price
#> 1 10:18:28:642      TR       1       1    666     EVILCORP 10.77
#> 2 10:18:28:687      TR       1       2    666     EVILCORP 10.77

unlink(ff)
```
