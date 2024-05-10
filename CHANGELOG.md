# 2024-05-06
If you use CNAMEs a trailing dot will now be added automatically.
This behavior is in line with other record types that use dns names.

This breaks using subdomain paths in CNAMEs and if you are using full domain names
in CNAMEs you will need to remove the trailing dot in your config.

`zones."example.org"."example".cname.data = "example2"`-> `example.example.org IN CNAME example2.`
You will now have to write it as:
`zones."example.org"."example".cname.data = "example2.example.org"`-> `example.example.org IN CNAME example2.example.org.`
