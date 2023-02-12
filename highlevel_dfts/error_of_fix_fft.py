from subprocess import check_output
import numpy as np 
from matplotlib import pyplot as plt

plot_error = 0
plot_for_bursts = 0

def print_float(s):
    print(s+", ")
    return float(s)

if plot_error:
    input_bits = range(20, 33)
    twiddle_bits = [13, 14, 16, 28]
    #titles = ["absolute error"]
elif plot_for_bursts:
    input_bursts = [1000, 2000, 3000, 4000] #range(10, 200, 30)
else:
    input_bits = range(5,8,1)
output_list = []
if plot_error:
    for twiddle_index in range(len(twiddle_bits)):
        output_list.append([])
        for amount_of_bits in input_bits:
            output = bytes.decode(check_output(
                ["./fix_fft",
                "-t",
                str(twiddle_bits[twiddle_index]),
                "-b",
                str(amount_of_bits),
                "-e",
                "SNS_Test_data_long_500.dat"
                ])).split()
            output = list(map(float ,output))
            output_list[twiddle_index].append(output)
elif plot_for_bursts:
    for amount_of_bursts in input_bursts:
        output = bytes.decode(check_output(
            ["./fix_fft",
            "-n",
            str(amount_of_bursts),
            "-b",
            "19",
            "-t",
            "6",
            "SNS_Test_data_long_500.dat"
            ])).split()
        output = list(map(float ,output))
        output_list.append(output)
else:
    for amount_of_bits in input_bits:
        output = bytes.decode(check_output(
            ["./fix_fft",
            "-n",
            "3000",
            "-b",
            "19",
            "-t",
            str(amount_of_bits),
            "SNS_Test_data_long_field.dat"
            ])).split()
        output = list(map(float ,output))
        output_list.append(output)

if(plot_error):
    for i in range(len(twiddle_bits)):
        output_for_plot = np.array(list(map(lambda x : x[2], output_list[i])))
        plt.subplot(len(twiddle_bits),1,i+1)
        plt.title("relative_error with "+str(twiddle_bits[i])+" bits")  
        plt.plot(np.array(input_bits),output_for_plot, "bo")
elif plot_for_bursts:
    for i in range(len(input_bursts)):
        output_for_plot = np.array(output_list[i])
        plt.subplot((len(input_bursts)+1) >> 1,2,i+1)
        plt.title("Number of bursts "+str(input_bursts[i]))  
        plt.plot(np.array(list(range(1,len(output_for_plot)))),output_for_plot[1:])
else:
    for i in range(len(input_bits)):
        output_for_plot = np.array(output_list[i])
        plt.subplot((len(input_bits)),1,i+1)
        plt.title("Number of bits "+str(input_bits[i]))  
        plt.plot(np.array(list(range(1,len(output_for_plot)))),output_for_plot[1:])



plt.show()
