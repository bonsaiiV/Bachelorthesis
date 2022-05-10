import numpy as np
from cmath import exp, pi, log


#x = [1, 4, 9, 16, -1, -4, -9, -16, 1, 4, 9, 16, -1, -4, -9, -16, 1, 4, 9, 16, -1, -4, -9, -16, 1, 4, 9, 16, -1, -4, -9, -16]
x = [y for y in range(0,(2<<15))]

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

def radix2_fft(input):
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
        unitroot = exp((-2j * pi)/(1 << (layer)))
        elements_per_block = 1 << (layer)
        for block in range(1 << (n-layer)):
            for k in range(elements_per_block >> 1):
            
               
                tmp = pow(unitroot, k)
                k_even = (block * elements_per_block)+k
                k_odd = k_even+(elements_per_block >> 1)
                tmp = tmp * output[k_odd]
                output[k_odd] = output[k_even] - tmp
                output[k_even] = output[k_even] + tmp


    return output

precision = 0
def compare_ctuple(tuple):
    return ( round(tuple[0].real, precision) == round(tuple[1].real, precision) 
        and  round(tuple[0].imag, precision) == round(tuple[1].imag, precision) )
output= radix2_fft(x)
results =  [(not compare_ctuple(tuple)) for tuple in zip(np.fft.fft(x), output)]
output2 = np.fft.fft(x)
for i in range(len(output)):
    if(results[i]):
        print(output2[i])        
        print(round(output[i].real, precision)+round(output[i].imag, precision)*1j, "\n")
#print(list(map(lambda y : round(y.real, precision)+round(y.imag, precision)*1j ,output)))
e_rate = np.divide(np.sum(results), len(output))
print(e_rate)