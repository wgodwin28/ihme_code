import sys
sys.path.append('/home/j/Project/COMIND/Water and Sanitation/Smoothing/GPR Code/')
import GPR
reload(GPR)
number_submodels = 1
iters = 1000
infile = '/home/j/Project/COMIND/Water and Sanitation/Smoothing/GPR Input/gpr_input_data_w_covar.csv'
outfile = '/home/j/Project/COMIND/Water and Sanitation/Smoothing/GPR Results/gpr_temp_output_w_covar.csv'
scale = 7
dv_list = 'lt_prev'
GPR.fit_GPR(infile, outfile, dv_list, scale, number_submodels, iters)
