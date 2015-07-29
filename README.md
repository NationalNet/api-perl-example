Example for interacting with NationalNet's REST API (Perl)
=========================================================

First, clone this repository.

```
git clone https://github.com/NationalNet/api-perl-example.git
```

Install dependencies

```
apt-get install libjson-perl libdigest-hmac-perl liburi-perl
```

Edit the following lines and enter your mynatnet username and api key.

```perl
my $user = ''; # your myNatNet username
my $api_key = ''; # api-key string found in myNatNet user profile
```

Now, you should be able to run the script. By default, nothing is printed to the CLI. Print statements have been left to ease debugging.
