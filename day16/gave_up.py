import re
import heapq as hq
from queue import Queue
part1=False#set to true for Part 1, False for Part 2
if part1:
    maxtime=30
else:
    maxtime=26
data=[[re.findall(r'(?<=Valve\s)[A-Z]+',x[0])[0], int(re.findall(r'[0-9]+',x[0])[0]),re.findall(r'[A-Z]+',x[1])]for x in [y.split(';') for y in open('input.txt').read().split('\n')]]
valves={x[0]:x[1] for x in data if x[1]>0}
neighs={x[0]:x[-1] for x in data}
dists={}
seen={}

#hq.heapify(h) pops in the following order  left to right on arguments of tuples, and low to high valuewise
for v in ['AA']+list(valves.keys()):
    for w in ['AA']+list(valves.keys()):
        if (v,w) not in dists:
            end=w
            frontier=[(0,v)]
            hq.heapify(frontier)
            costs={v:0}
            while not len(frontier)==0:
                prior,cur=hq.heappop(frontier)
                if cur==end:
                    dists[(v,w)]=costs[end]
                    dists[(w,v)]=costs[end]
                    break       
                for n in neighs[cur]:
                    new=costs[cur]+1
                    if n not in costs or costs[n]>new:
                        costs[n]=new
                        hq.heappush(frontier,(new,n))
neighs={key:[x for x in value if x in valves.keys()] for key,value in neighs.items() if key in valves}
highest=0
pairshigh=0
paths=Queue()
paths.put([0,0,'AA'])

bests={frozenset(['AA']):0}
while not paths.empty():    
    p=paths.get()
    s=p.copy()
    if not part1:
        for v in s[2:]:#finish out the time as if we didn't move again
            if v in valves:
                s[1]+=valves[v]*(maxtime-s[0])
        s[0]=maxtime
        hsh=(s[0],tuple(s[3:]))
        if hsh not in seen or seen[hsh]<s[1]:
            seen[hsh]=s[1]
    if len(p)==len(valves)+3:
        for v in p[2:]:
            if v in valves:
                p[1]+=valves[v]*(maxtime-p[0])
        p[0]=maxtime
        if not part1:
            hsh=(p[0],tuple(p[3:]))
            if hsh not in seen:
                seen[hsh]=p[1]
        if p[1]>highest:
            highest=p[1]
            bestpath=tuple(p)           
    else:
        cur=p[-1]
        news=[p+[new] for new in valves if new not in p ]
        for n in news:
            delta=dists[(cur,n[-1])]+1
            if n[0]+delta>=maxtime:
                for v in n[2:-1]:#finish out the time for all but the most recent node, since we couldn't get there in time
                    if v in valves:
                        n[1]+=valves[v]*(maxtime-n[0])
                n[0]=maxtime
                if not part1:
                    hsh=(n[0],tuple(n[3:]))
                    if hsh not in seen or seen[hsh]<n[1]:
                        seen[hsh]=n[1]
                
                if n[1]>highest:
                    highest=n[1]
                    bestpath=tuple(n)
            else:            
                n[0]+=delta
                for v in n[2:-1]:
                    if v in valves:
                        n[1]+=valves[v]*delta
                if not part1:
                    hsh=(n[0],tuple(n[3:]))
                    if hsh not in seen or seen[hsh]<n[1]:
                        seen[hsh]=n[1]
                paths.put(n)
if part1:
    print(highest)
else:
    bests={}
    for key,value in seen.items():
        if frozenset(key[1]) not in bests or bests[frozenset(key[1])]<value:
            bests[frozenset(key[1])]=value
    for key in bests:
        if len(key)<=len(valves)//2:
            other=frozenset([x for x in valves if x not in key])
            if other in bests and bests[key]+bests[other]>pairshigh:
                for otherkey in bests:
                    if otherkey.issubset(other):
                        tmp=bests[key]+bests[otherkey]
                        if pairshigh<tmp:
                            pairshigh=tmp              
    print(pairshigh)

