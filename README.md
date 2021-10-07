# img-mgr except with terraform and runway

this is img-mgr except with terraform and runway

## tfvars

i am choosing not to gitignore the tfvars files because runway needs them and there's really nothing sensitive in there anyway

## cloudfront alias

- `itsalwaysdns.tf` will create an alias DNS record in route53 and an SSL certificate in ACM to be used by cloudfront
- `main.tf` will conditionally configure cloudfront to use that alias as long as you have the `cf_alias` variable set

currently, these two modules kinda rely on each other. `itsalwaysdns.tf` relies on outputs from `main.tf`, but `main.tf` needs the resources to already be created. i guess i could do them in the same module, but i wanted to keep the dns stuff optional.

you also need to have a hosted zone in route53 already. `itsalwaysdns.tf` creates the record for you, but it expects the zone to exist already (specified as `hosted_zone`).

### NOTE: changing the domain name

if you want to change the domain name, you need to deploy `main.tf` with the `cf_alias` variable unset. if you just try to deploy `itsalwaysdns.tf` with a new domain, it will hang on trying to delete the previous certificate (which is still being used by cloudfront).