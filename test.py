#!/usr/bin/python

import math
import sys
import string


dic = {}
str = '   abasdfasdf  '

str.strip()
print str, "\n"
for tmp in str:
	dic[tmp] = dic.get(tmp, 0) + 1
print dic, "\n" 
exit 



#DIC
dic={}
str = "dsfasdfasdfasdf";
for tmp in str:
    dic[tmp] = dic.get(tmp, 0) + 1
print dic


#function
def test1( pIn, pOut):
    print "input: ", pIn,

test1("inHello", "outWorld")

#abs = lambda x : (x > 0 ? x : -x)
#tmp = abs(-1)
#print "abs(-1): ", tmp
