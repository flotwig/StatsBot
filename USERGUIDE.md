StatsBot
========

StatsBot is a bot which collects and displays detailed statistics about a channel, including user rankings, totals, and notable numbers. For an example, look at the [stats for #reddit](http://stats.irc.so/%23reddit.html)

To summon Statistics to your channel on Snoonet, simply invite it to your channel.  
`/invite Statistics #channel`

To remove Statistics from your channel on Snoonet, kick it out like you would any other user.  
`/kick #channel Statistics`

Users can get a link to your stats page in the channel by using the !stats command. For example:  
`<flotwig> !stats`  
`-Statistics- Stats for this channel can be found at http://stats.irc.so/%23reddit.html`

Note: Stats are not generated instantly, so it may take an hour or two for your stats to be generated initially. Please be patient.

Note for channel owners: If you operate an invite-only or otherwise join-restricted channel, please add an exception for StatsBot so that he can rejoin if he is ever rebooted.

Notes for IRCops: Please do not SAJOIN StatsBot to channels, it currently does not recognize the JOIN command in that way. Use INVITE instead.
