# RBL
# Instalation

Copy:
```
cp ./rbl.sh /usr/local/sbin/ 
```

# Usage
```
#rbl.sh -x 1.10.16.0 -c zen.spamhaus.org
IP: 1.10.16.0 RBL: zen.spamhaus.org
        QUERY: 0.16.10.1.zen.spamhaus.org
        Result: LISTED
        Output:
                0.16.10.1.zen.spamhaus.org. 60  IN      A       127.0.0.2
                0.16.10.1.zen.spamhaus.org. 60  IN      A       127.0.0.9

Summary:
        1.10.16.0 listed on zen.spamhaus.org
```

```
#cat /tmp/ip
1.10.16.1
1.10.16.3
2a0e:fa00::1

#cat /tmp/rbl
zen.spamhaus.org

#rbl.sh -i /tmp/ip -r /tmp/rbl
IP: 1.10.16.1 RBL: zen.spamhaus.org
        QUERY: 1.16.10.1.zen.spamhaus.org
        Result: LISTED
        Output:
                1.16.10.1.zen.spamhaus.org. 60  IN      A       127.0.0.2
                1.16.10.1.zen.spamhaus.org. 60  IN      A       127.0.0.9
IP: 1.10.16.3 RBL: zen.spamhaus.org
        QUERY: 3.16.10.1.zen.spamhaus.org
        Result: LISTED
        Output:
                3.16.10.1.zen.spamhaus.org. 60  IN      A       127.0.0.2
                3.16.10.1.zen.spamhaus.org. 60  IN      A       127.0.0.9
IP: 2a0e:fa00::1 RBL: zen.spamhaus.org
        QUERY: 1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.a.f.e.0.a.2.zen.spamhaus.org
        Result: LISTED
        Output:
                1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.a.f.e.0.a.2.zen.spamhaus.org. 60 IN A 127.0.0.2
                1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.a.f.e.0.a.2.zen.spamhaus.org. 60 IN A 127.0.0.9

Summary:
        1.10.16.1 listed on zen.spamhaus.org
        1.10.16.3 listed on zen.spamhaus.org
        2a0e:fa00::1 listed on zen.spamhaus.org
```

# Changes mode
First run:
```
#rbl.sh -i /tmp/ip -r /tmp/rbl -s /tmp/dir
(...)
Summary:
        1.10.16.1 listed on zen.spamhaus.org
        1.10.16.3 listed on zen.spamhaus.org
        2a0e:fa00::1 listed on zen.spamhaus.org

Changes:
        + 1.10.16.1 zen.spamhaus.org
        + 1.10.16.3 zen.spamhaus.org
        + 2a0e:fa00::1 zen.spamhaus.org

```
Second run:
```
#rbl.sh -i /tmp/ip -r /tmp/rbl -s /tmp/dir
(...)
Summary:
        1.10.16.1 listed on zen.spamhaus.org
        1.10.16.3 listed on zen.spamhaus.org
        2a0e:fa00::1 listed on zen.spamhaus.org

Changes:
        No changes

```
Third run (1.10.16.1 removed from RBL, 1.10.16.10 added to RBL)
```
(...)
Summary:
        1.10.16.10 listed on zen.spamhaus.org
        1.10.16.3 listed on zen.spamhaus.org
        2a0e:fa00::1 listed on zen.spamhaus.org

Changes:
        - 1.10.16.1 zen.spamhaus.org
        + 1.10.16.10 zen.spamhaus.org


```
# Hooks
Hooks are executed with '$in' variable. <br>
$in variable syntax:<br>
1)hook (-h)
```
{-|+} ip-addr rbl|{-|+} ip-addr rbl (...) 
- 1.10.16.3 zen.spamhaus.org|+ 1.10.16.22 zen.spamhaus.org|+ 1.10.16.33 zen.spamhaus.org|+ 2a0e:fa00::4 zen.spamhaus.org
```
2)addhook (-a), delhook (-d)
```
ip-addr rbl|ip-addr rbl (...) 
1.10.16.10 zen.spamhaus.org|1.10.16.33 zen.spamhaus.org|2a0e:fa00::2 zen.spamhaus.org

```

# Domain mode
```
#rbl.sh -f -x dbltest.com -c dbl.spamhaus.org
IP: dbltest.com RBL: dbl.spamhaus.org
        QUERY: dbltest.com.dbl.spamhaus.org
        Result: LISTED
        Output:
                dbltest.com.dbl.spamhaus.org. 60 IN     A       127.0.1.2

Summary:
        dbltest.com listed on dbl.spamhaus.org
```


