import numpy as np
from cmath import exp, pi, log
from operator import add
from random import random

def get_sin(T, samples):
    return [5*np.sin(np.pi * y /T) for y in range(samples)]

def get_cos(T, samples):
    return [5*np.cos(np.pi * y /T) for y in range(samples)]


x = [1, 4, 9, 16, -1, -4, -9, -16, 1, 4, 9, 16, -1, -4, -9, -16]#, 1, 4, 9, 16, -1, -4, -9, -16, 1, 4, 9, 16, -1, -4, -9, -16]
N = 1<<15
T1 = 1<<13
#x = [y for y in range(0,N)]
#x = get_sin(T1, N)
#x = get_cos(T1, N)
#x = list( map(add , map(add, get_sin( 16, N), get_cos( 32, N)), [random()-0.5 for y in  range(N)] ) )

def pow(b, e):
    return exp(log(b)*e)

def lookup(index, n):
    res = 0
    for i in range(n):
        res = res << 1
        res += (index & 1)
        index = index >> 1
    return res
        
def get(index, list):
    if index >= len(list): return 0
    return list[index]

def calculate_unitroot1(elements_per_block, k):
    return exp((-2j * pi)*k/elements_per_block)

def calculate_unitroot2(elements_per_block, k):
    return np.cos(2*pi*k/elements_per_block) + np.sin(-2*pi*k/elements_per_block)*1j

def radix2_fft(input, calculate_unitroot):
    n = 0
    divisor = len(input)
    one_more = 0
    while divisor:
        n += 1
        one_more += 1 & divisor
        divisor = divisor >> 1
    if not one_more - 1:
        n -= 1
    length = 1 << n 
    output = []
    for i in range(0,length,2):
        x_even = lookup(i, n)
        x_odd = lookup(i+1, n)
        output.append(get(x_even, input) + get(x_odd, input))
        output.append(get(x_even, input) - get(x_odd, input))
    
    for layer in range(2, n+1):
        #unitroot = exp((-2j * pi)/(1 << (layer)))
        elements_per_block = 1 << (layer)
        for block in range(1 << (n-layer)):
            for k in range(elements_per_block >> 1):
            
               
                unitroot = calculate_unitroot(elements_per_block, k)
                k_even = (block * elements_per_block)+k
                k_odd = k_even+(elements_per_block >> 1)
                tmp = unitroot * output[k_odd]
                output[k_odd] = output[k_even] - tmp
                output[k_even] = output[k_even] + tmp


    return output

precision = 6
def compare_ctuple(tuple):
    return ( round(tuple[0].real, precision) == round(tuple[1].real, precision) 
        and  round(tuple[0].imag, precision) == round(tuple[1].imag, precision) )

output1 = radix2_fft(x, calculate_unitroot1)
output2 = radix2_fft(x, calculate_unitroot2)
expected_values = np.fft.fft(x)
results1 =  [(not compare_ctuple(tuple)) for tuple in zip(expected_values, output1)]
results2 =  [(not compare_ctuple(tuple)) for tuple in zip(expected_values, output2)]

for i in range(len(output1)):
    if(results1[i]):
        print(expected_values[i])        
        print(round(output1[i].real, 9)+round(output1[i].imag, 9)*1j, "\n")
print(list(map(lambda y : round(y.real, precision)+round(y.imag, precision)*1j ,output1)))
e_rate1 = np.divide(np.sum(results1), len(output1))
e_rate2 = np.divide(np.sum(results2), len(output2))
print(x)
print("error rate with polarcoordinates:",e_rate1)
print("error rate with cos and sin:",e_rate2)
print("with precision", precision)