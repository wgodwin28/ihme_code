//do /homes/jfrostad/_code/risks/envir_radon/exp/02_save.do

 do "J:/WORK/05_risk/central/code/risk_utils/risk_info.ado"
* do "J:/WORK/05_risk/central/code/risk_utils/risk_info.ado"
 risk_info, risk(air_pm)	

do "/home/j/WORK/10_gbd/00_library/functions/save_results.do"

save_results, modelable_entity_id(8746) description(should match gbd2015 best, with interpolated annual pafs) in_dir(/share/gbd/WORK/05_risk/02_models/02_results/air_pm/paf/12/annual_draws) risk_type(paf) mark_best(yes) morbidity(yes) mortality(yes) years(1990 1991 1992 1993 1994 1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015)