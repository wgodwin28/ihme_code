'''
Author:     Kyle Foreman
Date:       21 June 2011
Purpose:    Run GPR on the spacetime predictions
'''

# import the necessary modules
from pymc import gp
import numpy as np
from pylab import rec2csv, csv2rec
from numpy.lib import recfunctions
import sys

# define program
def fit_GPR(infile, outfile, dv_list, scale, number_submodels, iters):
    # load in the data
    all_data = csv2rec(infile, use_mrecords=False)
    for m in range(number_submodels):
        all_data = np.delete(all_data, np.where(np.isnan(all_data['spacetime_' + str(m+1)]))[0], axis=0)
        
    # Investigate error thrown for HKG, MAC, and SGP... they don't have data, but don't know why this is breaking line 62
    ##all_data = all_data[all_data['iso3'] != "HKG"]
    ##all_data = all_data[all_data['iso3'] != "MAC"]
    ##all_data = all_data[all_data['iso3'] != "SGP"]

    # find the list of years for which we need to predict
    year_list = np.unique(all_data.year)

    # find the list of country/age groups
    country_age = np.array([all_data.iso3[i] for i in range(len(all_data))])
    country_age_list = np.repeat(np.unique(country_age), len(year_list))

    # make empty arrays in which to store the results
    draws = [np.empty(len(country_age_list), 'float') for i in range(iters*number_submodels*2)]
    iso3 = np.empty(len(country_age_list), '|S3')
    # age_group = np.empty(len(country_age_list), 'int')
    year = np.empty(len(country_age_list), 'int')

    # loop through country/age groups
    for ca in np.unique(country_age_list):
            
        print('GPRing ' + ca)

        # subset the data for this particular country/age
        ca_data = all_data[country_age==ca]

        # subset just the observed data
        if ca_data['lt_prev'].dtype != '|O8':
            ca_observed = ca_data[(np.isnan(ca_data['lt_prev'])==0)]
            if len(ca_observed) > 1:
                has_data = True
            else:
                has_data = False
        else:
            has_data = False

        # loop through each submodel
        for m in range(number_submodels):

            # identify the dependent variable for this model
            dv = dv_list[m]

            # loop through spacetime/linear
            for x,t in enumerate(['spacetime']):

                # make a list of the spacetime predictions
                ca_prior = np.array([np.mean(ca_data[t + '_' + str(m+1)][ca_data.year==y]) for y in year_list])

                # find the amplitude for this country/age
                amplitude = np.mean(ca_data[t + '_amplitude_' + str(m+1)])

                # make a linear interpolation of the spatio-temporal predictions to use as the mean function for GPR
                def mean_function(x) :
                    return np.interp(x, year_list, ca_prior)

                # setup the covariance function
                M = gp.Mean(mean_function)
                C = gp.Covariance(eval_fun=gp.matern.euclidean, diff_degree=2, amp=amplitude, scale=scale)

                # observe the data if there is any
                if has_data:
                    gp.observe(M=M, C=C, obs_mesh=ca_observed.year, obs_V=ca_observed[t + '_data_variance_' + str(m+1)], obs_vals=ca_observed['lt_prev'])

                # draw realizations from the data
                realizations = [gp.Realization(M, C) for i in range(iters)]

                # save the data for this country/age into the results array
                iso3[country_age_list==ca] = ca[0:3]
                # age_group[country_age_list==ca] = ca[4:]
                year[country_age_list==ca] = year_list.T
                for i in range(iters):
                    draws[((2*m+x)*iters)+i][country_age_list==ca] = realizations[i](year_list)

    # save the results
    print('Saving GPR results')
    names = ['iso3','age_group','year']
    results = np.core.records.fromarrays([iso3,year], names=names)
    for m in range(number_submodels):
        for x,t in enumerate(['spacetime']):
            for i in range(iters):
                results = recfunctions.append_fields(results, 'gpr_' + str(m+1) + '_' + t + '_d' + str(i+1), draws[((2*m+x)*iters)+i])
            results = recfunctions.append_fields(results, 'gpr_' + str(m+1) + '_' + t + '_mean', np.mean(draws[((2*m+x)*iters):((2*m+x+1)*iters)], axis=0))
        rec2csv(results, outfile)

fit_GPR(sys.argv[1], sys.argv[2], sys.argv[3], float(sys.argv[4]), int(sys.argv[5]), int(sys.argv[6]))
