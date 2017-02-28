import numpy as np
import sys

model_path = sys.argv[1]
model_name = 'ctoc'
file_name = model_path + '/' + model_name + '.npz'
model = np.load(file_name)
valid_errs = model['history_errs']
least_valid_err = np.argmin(valid_errs)
# print valid_errs
print least_valid_err, valid_errs[least_valid_err]

