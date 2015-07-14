
<cfset id = urlEncodedFormat(hash("ray@camdenfamily.com"))>

<cfoutput>
<p>
<img src="index.cfm?gravatar_id=#id#">
</p>
</cfoutput>

<cfset id = urlEncodedFormat(hash("rayxxxxxxxxx@camdenfamily.com"))>

<cfoutput>
<p>
<img src="index.cfm?gravatar_id=#id#">
</p>
</cfoutput>
