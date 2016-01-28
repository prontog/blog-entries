[Wireshark](https://www.wireshark.org/) is an amazing tool. It is open source, works on all major platforms, has powerful capture/display filters, has a very strong developer and user communities and it even has an annual [conference](http://sharkfest.wireshark.org/). At the company where I work, there are people using it daily to analyze packets and troubleshoot our network. Personally I don't use it daily but when I need to troubleshoot the communication between our programs it helps a lot.

> DID YOU KNOW THAT: Wireshark can be used in the command line with the [TShark](https://www.wireshark.org/docs/man-pages/tshark.html) utility?

As I already mentioned, Wireshark has powerful filter capabilities, which you can use to search for distinctive parts of your message. This is very powerful for all the supported protocols. For example you can use `tcp.port == 9001` to get the communication on port 9001 (source or target). This type of filtering works because there is a TCP dissector installed with Wireshark. Of course this is not the only dissector install with Wireshark. In the *Protocols* section in the *Preferences* dialog you will find the full list. If you want to filter messages of a protocol with no dissector you can use the frame object. For example to look for messages containing the string "EVIL" you can use the following filter:

```
frame contains "EVIL"
```

Actually this filter will return all frames containing the string. Not the actual messages. If for example each frame contains 10 messages, then goodluck finding them. As you can imagine, this can become tiresome.