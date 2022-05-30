from subprocess import check_output
import numpy as np 
from matplotlib import pyplot as plt

plot_for_bits = 0


if plot_for_bits:
    input_bits = range(16, 33)
    titles = ["absolute errors for sensor 1","absolute errors for sensor 2", "relative errors for sensor 1", "relative errors for sensor 2"]
else:
    input_bits =[18, 20, 22, 24]
output_list = []
for amount_of_bits in input_bits:
    output = bytes.decode(check_output(["./fix_fft", str(amount_of_bits), "SNS_Test_data_ampl.dat"])).split()
    output = list(map(float ,output))
    output_list.append(output)

if(plot_for_bits):
    for i in range(0,len(output)):
        output_for_plot = np.array(list(map(lambda x : x[i], output_list)))
        plt.subplot(2,2,i+1)
        plt.title(titles[i])  
        plt.plot(np.array(input_bits),output_for_plot)
else:
    for i in range(0,len(input_bits)):
        output_for_plot = np.array(output_list[i])
        plt.subplot(2,2,i+1)
        plt.title("Number of bits "+str(input_bits[i]))  
        plt.plot(np.array(list(range(0,len(output_for_plot)))),output_for_plot)



plt.show()
