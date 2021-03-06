# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""
#os.chdir("C:/Users/wgodwin")

import os
import pip
import ssl
!pip install "C:/Users/wgodwin/Desktop/temperature/ecmwf-api-client-python 2.tgz" ##this works from command line
#pip install https://software.ecmwf.int/wiki/download/attachments/56664858/ecmwf-api-client-python.tgz
!/usr/bin/env python
from ecmwfapi import ECMWFDataServer
server = ECMWFDataServer()
server.retrieve({
    "class": "ei",
    "dataset": "era20c",
    "date": "1990-01-01/to/2010-12-31",
    "expver": "1",
    "levtype": "sfc",
    "param": "167.128",
    "stream": "oper",
    "time": "00:00:00/06:00:00/12:00:00/18:00:00",
    "type": "an",
    "grid": "1/1",
    "target": "J:/temp/wgodwin/temperature/exposure/raw_data/downloaded/era_c/era_c_1990_2010.nc", # Change
    "format": "netcdf",
})

#ERA Interim query
from ecmwfapi import ECMWFDataServer
server = ECMWFDataServer()
server.retrieve({
    "class": "ei",
    "dataset": "interim",
    "date": "1987-01-01/to/1988-12-31",
    "expver": "1",
    "grid": "0.5/0.5",
    "levtype": "sfc",
    "param": "167.128", # "167.128"-2 meter temp, "168.128"-dew point temp
    "step": "0",
    "stream": "oper",
    "time": "00:00:00/06:00:00/12:00:00/18:00:00",
    "type": "an",
    "target": "J:/temp/wgodwin/temperature/exposure/raw_data/downloaded/era_interim/era_int_1987_88.nc", # Change
    "format": "netcdf",
})

#ERA 5 query
from ecmwfapi import ECMWFDataServer
server = ECMWFDataServer()
server.retrieve({
    "class": "ea",
    "dataset": "era5",
    "date": "2017-01-01/to/2017-12-31",
    "expver": "1",
    "grid": "0.5/0.5",
    "levtype": "sfc",
    "number": "0/1/2/3/4/5/6/7/8/9",
    "param": "167.128", # "167.128"-2 meter temp, "168.128"-dew point temp
    "step": "0",
    "stream": "enda",
    "time": "00:00:00/06:00:00/12:00:00/18:00:00",
    "type": "an",
    "target": "J:/temp/wgodwin/temperature/exposure/raw_data/downloaded/era_5/est_test.nc", # Change
    "format": "netcdf",
})


from ecmwfapi import ECMWFDataServer
server = ECMWFDataServer()
server.retrieve({
    "class": "ei",
    "dataset": "interim",
    "date": "2005-01-01/to/2005-12-31",
    "expver": "1",
    "grid": "0.5/0.5",
    "levtype": "sfc",
    "param": "228.128", # "167.128"-2 meter temp, "168.128"-dew point temp
    "step": "3",
    "stream": "oper",
    "time": "12:00:00",
    "type": "fc",
    "target": "C:/Users/wgodwin/Desktop/biostat_555/exercises/data/final/precip_2005.nc", # Change
    "format": "netcdf",
})

import pandas as pd
from transmogrifier.maths import extrapolate

file_path = "/home/j/temp/wgodwin/save_results/covariates/sanitation_sev_interm2.csv"
df = pd.read_csv(file_path)
extrap_df = extrapolate(data_df=df, draw_df=None, id_col=['location_id', 'sex_id', 'ihme_loc_id'],
                        time_col='year_id', transform = 'logit', response_col = 'mean',
                        first_time=1990, back_to=1980)
df = pd.read_csv(file_path)                        
final = extrap_df.append(df)

final.to_csv("/home/j/WORK/05_risk/risks/wash_sanitation/products/sev/1/annual.csv")






sev.dt <- get_outputs(topic = "rei", location_id = "all", year_id = seq(1990,2016), measure_id = 29, rei_id = 84, metric_id = 3, 
	age_group_id = 22, gbd_round_id = 4, sex_id = 3)