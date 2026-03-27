import sys, getopt
import sgems
from math import *

# Felipe Santibanez & Thomas Peet 2014
# fsantibanezleal@ug.uchile.cl
# fsantibanez@med.uchile.cl

# We provide a batch method in order to create realizations from MPS using SGems

# Input required:
# 	Images 
#	 	Training Image (defines probability distribution and channel patterns)
#		Hard Data (Define a #	Internal Params
#   	Grid   : 2D representation of discrete space. ()
#		nReals : Number of realizations for each configuration
# This Script creates and saves nReals realizations of the field.
#

###########################################################################################
###########################################################################################
##############         Main Program                                   #####################
###########################################################################################
###########################################################################################
#def main(argv):
#fileIT  = ''
#fileHD  = ''
#fileOut = ''
print "Starting Batch Program"

# KEEP FORMAT of comments!!!! Required To Matlab modifications
# Preliminary params

#MATLAB_MOD_SGEMSDATA
sgemsDir    = 'C:/SGeMS-x64-Beta/'
sNameTI     = 'TI'
sNameHD     = 'harddata'
#MATLAB_MOD_NUM_REALIZATIONS
nReals  	= 5
#MATLAB_MOD_IMAGES_DIMENSIONS
nX      	= 200
nY      	= 200
#MATLAB_MOD_IMAGES_PROPS
marginalCDF0 = 0.53435
marginalCDF1 = 0.46565
#MATLAB_MOD_OUTFOLDER
outFolder    = 'C:/SIMS/'
#MATLAB_MOD_OUTSUBNAME
outSubName   = 'Simulations.gslib'

searchEMax   = 50
searchEMed   = 50
searchEMin   = 50

nLayers 	= 1000    # Not sure yet
nAN     	= -999999 # unavailable data 

orig_seed	= 211175

in_TI_File  = sgemsDir + 'TI' + '.sgems::All'
in_HD_File  = sgemsDir + 'HD' + '.sgems::All'

outFile      = outFolder + outSubName

### Continue with algorithm!!!
print "Creating Grid and applying basic params"
print "1. Creating layers"
#CreateLayers( nLayers, nX, nY )
print "2. Loading TI & HD"
#LoadData( sNameTI, sNameHD )
# Load Objects
sgems.execute('LoadObjectFromFile ' + in_TI_File)
sgems.execute('LoadObjectFromFile  ' + in_HD_File)

print "Doing realizations"
# Create grid and run algorithm
sgems.execute('NewCartesianGrid    grilla::' + str(nX) + '::' + str(nY) + '::1::1.0::1.0::1.0::0::0::0')
sgems.execute('RunGeostatAlgorithm  snesim_std::/GeostatParamUtils/XML::<parameters>  <algorithm name="snesim_std" />     <Cmin  value="1" />     <Constraint_Marginal_ADVANCED  value="0" />     <resimulation_criterion  value="-1" />     <resimulation_iteration_nb  value="1" />     <Nb_Multigrids_ADVANCED  value="3" />     <Debug_Level  value="0" />     <Subgrid_choice  value="0"  />     <expand_isotropic  value="1"  />     <expand_anisotropic  value="0"  />     <aniso_factor  value="    " />     <Use_Affinity  value="0"  />     <Use_Rotation  value="0"  />     <Hard_Data  grid="' + sNameHD + '" region="" property="porosity"  />     <use_pre_simulated_gridded_data  value="0"  />     <Use_ProbField  value="0"  />     <ProbField_properties count="0"   value=""  />     <TauModelObject  value="1 1" />     <use_vertical_proportion  value="0"  />     <GridSelector_Sim value="grilla" region=""  />     <Property_Name_Sim  value="porosidad" />     <Nb_Realizations  value="' + str(nReals) + '" />     <Seed  value="' + str(orig_seed) + '" />     <PropertySelector_Training  grid="' + sNameTI + '" region="" property="porosity"  />     <Nb_Facies  value="2" />     <Marginal_Cdf  value="' + str(marginalCDF0) + ' ' + str(marginalCDF1) + '" />     <Max_Cond  value="60" />     <Search_Ellipsoid  value="' + str(searchEMax)  + ' ' + str(searchEMed)  + ' '  + str(searchEMin)  + ' 0 0 0" />  </parameters> ') 

#Saving outcomes
requiredStr = '::porosidad__real0'
for idx in range(1,nReals):
    requiredStr = requiredStr + '::porosidad__real' + str(idx)

sgems.execute('SaveGeostatGrid  grilla::' + outFile + '::gslib::0' + requiredStr)

print "Ending batch program..."

# Keep next  
#MATLAB_MOD_ENDFILE
