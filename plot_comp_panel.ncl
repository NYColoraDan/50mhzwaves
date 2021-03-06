;
; File: plot_comp_panel.ncl
;
; Author: D. Adriaansen
;
; Date: 29 Apr 2016
;
; Purpose:
;
; Notes:
;_________________________________________________________________________________

;################################### User Config ##############################;

; Path to input netCDF files
ncpath = "/d1/dadriaan/paper/data/masked"

; Monsoon days
mbeg = 13 ; Note- actually day 14, but day 0 = day 1 on zpanel plot
mdays = 20
;mend = 32 ; Note- actually day 33, but day 0 = day 1 on zpanel plot

; Break days
bbeg = 36 ; Note- actually day 37, but day 0 = day 1 on zpanel plot
bdays = 23
;bend = 58 ; Note- actually day 59, but day 0 = day 1 on zpanel plot

; What hour is the beginning of a day? In Darwin, we will use 02Z to 02Z, or 1130-1130 local time.
beghr = 2

; What day number do we want to look at? Use any negative number to inicate we want all days
if .not.isvar("daynum") then
  daynum = -1
end if

; Variable to make sure we've figured out how to slice the data
foundoffset = False

; What wind component?
windcomp = "v"

; Break or monsoon?
bm = "break"

; What version of the data? (raw, data, prime)?
; raw = raw data
; data = raw data with precip mask applied
; prime = perturbation wind
vers = "prime"

; Path to image output
imgout = "/d1/dadriaan/paper/images/comp_"+vers

; Print configuration for user:
print("")
print("#############################")
print("")
print("DAY BEGINS AT: "+sprinti("%02i",tointeger(beghr))+"Z")
if daynum.lt.0 then
  print("PLOTTING DATA FOR ALL DAYS")
else
  print("PLOTTING DATA FOR DAY NUMBER: "+daynum)
end if
print("")
print("############################")
print("")

;####################################################################################;

; NCL Libraries
load "/home/dadriaan/cvs/pat/dadriaan/scripts/ncl/load_ncl_libs.ncl"
load "/home/dadriaan/cvs/pat/dadriaan/scripts/ncl/ncl_usr_funcs.ncl"

; Open all the files
allfiles = systemfunc("ls "+ncpath+"/*2006*.nc")
fin = addfiles(allfiles,"r")
ListSetType(fin,"cat")

; Read the data
bf = fin[0]->bf
pagl = fin[0]->pagl
unix_time = fin[:]->unix_time
omean = fin[:]->omean
zmean = fin[:]->zmean
mmean = fin[:]->mmean
omegpass1 = fin[:]->omegpass1
zonalpass1 = fin[:]->zonalpass1
meridpass1 = fin[:]->meridpass1

; Determine the number of times and heights
ntimes = dimsizes(unix_time)
numhgts = dimsizes(pagl)

; Print info for user
nhrsdata = dimsizes(unix_time)/60
ndaysdata = dimsizes(unix_time)/1440
print("PROCESSING "+ndaysdata+" DAYS OF DATA ("+nhrsdata+" HOURS)")
print("TOTAL MINUTES = "+dimsizes(unix_time))
print("")

; Determine the index of the beginning and the end of the monsoon and break periods
; Need to set the beginning index for the break period
begmonsoon = (beghr*60)+(1440*mbeg)
print("begmonsoon = "+begmonsoon)
print("mbegunix = "+unix_time(begmonsoon))
endmonsoon = begmonsoon+(1440*(mdays-1))
print("endmonsoon = "+endmonsoon)
print("mendunix = "+unix_time(endmonsoon))
ndayssoon = ((endmonsoon-begmonsoon)/1440)
print("ndayssoon = "+ndayssoon)
print("")
begbreak = (beghr*60)+(1440*bbeg)
print("begbreak = "+begbreak)
print("bbegunix = "+unix_time(begbreak))
endbreak = begbreak+(1440*(bdays-1))
print("endbreak = "+endbreak)
print("bendunix = "+unix_time(endbreak))
ndaysbreak = ((endbreak-begbreak)/1440)
print("ndaysbreak = "+ndaysbreak)
print("")

; Subset begin and end for averaging for calculating perturbations
if bm.eq."monsoon" then
  sub_beg = begmonsoon
  sub_end = endmonsoon
else
  sub_beg = begbreak
  sub_end = endbreak
end if
print("CALCULATING MEAN FOR PERTURBATION FROM:")
print(""+prettyPrint(unix_time(sub_beg),"ymdhms"))
print("TO")
print(""+prettyPrint(unix_time(sub_end),"ymdhms"))
print("")

; Calculate the purturbation (subtract off mean)
print("CALCULATIUNG PERTURBATION WINDS.")
print("")
meanw = new((/numhgts/),float)
sdevw = new((/numhgts/),float)
nptsw = new((/numhgts/),float)
meanu = new((/numhgts/),float)
sdevu = new((/numhgts/),float)
nptsu = new((/numhgts/),float)
meanv = new((/numhgts/),float)
sdevv = new((/numhgts/),float)
nptsv = new((/numhgts/),float)
do z=0,numhgts-1,1
  ;print("CALCULATING MEANS FOR Z = "+pagl(z))
  subw = omegpass1(sub_beg:sub_end,z)
  subu = zonalpass1(sub_beg:sub_end,z)
  subv = meridpass1(sub_beg:sub_end,z)
  subu@_FillValue = bf
  subw@_FillValue = bf
  subv@_FillValue = bf
  goodw = ind(.not.ismissing(subw))
  goodu = ind(.not.ismissing(subu))
  goodv = ind(.not.ismissing(subv))
  if ismissing(goodw(0)) then
    meanw(z) = bf
    sdevw(z) = bf
    nptsw(z) = bf
  else
    ;print("CALCULATING MEAN WWIND WITH "+dimsizes(goodw)+" POINTS.")
    meanw(z) = avg(subw(goodw))
    sdevw(z) = stddev(subw(goodw))
    nptsw(z) = dimsizes(goodw)
  end if
  ;print("meanw = "+meanw(z))
  ;print("sdevw = "+sdevw(z))
  if ismissing(goodu(0)) then
    meanu(z) = bf
    sdevu(z) = bf
    nptsu(z) = bf
  else
    ;print("CALCULATING MEAN UWIND WITH "+dimsizes(goodu)+" POINTS.")
    meanu(z) = avg(subu(goodu))
    sdevu(z) = stddev(subu(goodu))
    nptsu(z) = dimsizes(goodu)
  end if
  ;print("meanu = "+meanu(z))
  ;print("sdevu = "+sdevu(z))
  if ismissing(goodv(0)) then
    meanv(z) = bf
    sdevv(z) = bf
    nptsv(z) = bf
  else
    ;print("CALCULATING MEAN VWIND WITH "+dimsizes(goodv)+" POINTS.")
    meanv(z) = avg(subv(goodv))
    sdevv(z) = stddev(subv(goodv))
    nptsv(z) = dimsizes(goodv)
  end if
  ;print("meanv = "+meanv(z))
  ;print("sdevv = "+sdevv(z))
  ;print("")

  ; Clean up
  delete([/goodw,goodv,goodu/])
end do

; Define new matrices to hold the means
wmean = new((/dimsizes(omegpass1)/),float)
umean = new((/dimsizes(zonalpass1)/),float)
vmean = new((/dimsizes(meridpass1)/),float)

; Fill the means
do nz=0,numhgts-1,1
  wmean(:,nz) = meanw(nz)
  umean(:,nz) = meanu(nz)
  vmean(:,nz) = meanv(nz)
end do

; Subtract off the mean
wturb = omegpass1-wmean
uturb = zonalpass1-umean
vturb = meridpass1-vmean

; Name dimensions
wturb!0 = "time"
wturb!1 = "height"
vturb!0 = "time"
vturb!1 = "height"
uturb!0 = "time"
uturb!1 = "height"

print("PERTURBATION COMPLETE.")
print("")

; Create 2D variable to hold the composite wind data
print("CREATING THE COMPOSITE PLOT.")
print("")
wcomp = new((/1440,numhgts/),float)
wcomp@_FillValue = bf
wcomp!0 = "time"
wcomp!1 = "height"
wsdev = new((/1440,numhgts/),float)
wsdev@_FillValue = bf
wsdev!0 = "time"
wsdev!1 = "height"
wnpts = new((/1440,numhgts/),float)
wnpts@_FillValue = bf
wnpts!0 = "time"
wnpts!1 = "height"

; Now for each time, collect all the profiles from each day of interest for that time and do stuff
; Loop over every minute in a "day" (we are aggregating all minutes from every day in the period
do t=0,1439,1
;do t=1200,1200,1
  ;print("")
  ;print("COLLECTING ALL MINUTE "+t+" TIMES FROM ALL DAYS")
  ;print("")
  ; At each time, loop over every height and collect data forward in time matching the same minutes
  do z=0,numhgts-1,1
  ;do z=20,20,1
    ;print("")
    ;print("PROCESSING HEIGHT "+z)
    ;print("")
    ; Create a temporary array to hold the minutes that we're at from each day in the period (break/monsoon)
    if bm.eq."monsoon" then
      tmp = new((/ndayssoon/),float)
      daysinloop = ndayssoon
    else
      tmp = new((/ndaysbreak/),float)
      daysinloop = ndaysbreak
    end if
    tmp@_FillValue = bf
    
    ; Loop over every day in the period and collect the relevant data
    do nd=0,daysinloop-1,1

      ; Vertical velocity
      if windcomp.eq."w" then
        if vers.eq."raw" then
          if bm.eq."monsoon" then
            tmp(nd) = omean(((begmonsoon+t)+(nd*1440)),z)
          else
            tmp(nd) = omean(((begbreak+t)+(nd*1440)),z)
          end if
        end if
        if vers.eq."data" then
          if bm.eq."monsoon" then
            tmp(nd) = omegpass1(((begmonsoon+t)+(nd*1440)),z)
          else
            tmp(nd) = omegpass1(((begbreak+t)+(nd*1440)),z)
          end if
        end if
        if vers.eq."prime" then
          if bm.eq."monsoon" then
            tmp(nd) = wturb(((begmonsoon+t)+(nd*1440)),z)
          else
            tmp(nd) = wturb(((begbreak+t)+(nd*1440)),z)
          end if
        end if
      end if

     ; Zonal wind
      if windcomp.eq."u" then
        if vers.eq."raw" then
          if bm.eq."monsoon" then
            tmp(nd) = zmean(((begmonsoon+t)+(nd*1440)),z)
          else
            tmp(nd) = zmean(((begbreak+t)+(nd*1440)),z)
          end if
        end if
        if vers.eq."data" then
          if bm.eq."monsoon" then
            tmp(nd) = zonalpass1(((begmonsoon+t)+(nd*1440)),z)
          else
            tmp(nd) = zonalpass1(((begbreak+t)+(nd*1440)),z)
          end if
        end if
        if vers.eq."prime" then
          if bm.eq."monsoon" then
            tmp(nd) = uturb(((begmonsoon+t)+(nd*1440)),z)
          else
            tmp(nd) = uturb(((begbreak+t)+(nd*1440)),z)
          end if
        end if
      end if

     ; Meridional wind
      if windcomp.eq."v" then
        if vers.eq."raw" then
          if bm.eq."monsoon" then
            tmp(nd) = mmean(((begmonsoon+t)+(nd*1440)),z)
          else
            tmp(nd) = mmean(((begbreak+t)+(nd*1440)),z)
          end if
        end if
        if vers.eq."data" then
          if bm.eq."monsoon" then
            tmp(nd) = meridpass1(((begmonsoon+t)+(nd*1440)),z)
          else
            tmp(nd) = meridpass1(((begbreak+t)+(nd*1440)),z)
          end if
        end if
        if vers.eq."prime" then
          if bm.eq."monsoon" then
            tmp(nd) = vturb(((begmonsoon+t)+(nd*1440)),z)
          else
            tmp(nd) = vturb(((begbreak+t)+(nd*1440)),z)
          end if
        end if
      end if

      ;;print("nd = "+nd)
      ;;print("t = "+t)
      ;;print("begmonsoon = "+begmonsoon)
      ;;timew(nd) = precipflag((begmonsoon+t)+(nd*1440))
      ;;print("utimes = "+utimes((begmonsoon+t)+(nd*1440)))
      ;;print(""+prettyPrint(utimes((begmonsoon+t)+(nd*1440)),"ymdhms"))
    end do

    ; Now that we have the data, store the mean, stdev, and number of good points for the current t,z
    tvalid = ind(.not.ismissing(tmp))
    if dimsizes(tvalid).gt.1 .and. .not.ismissing(tvalid(0)) then
      wnpts(t,z) = dimsizes(tvalid)
      wcomp(t,z) = avg(tmp(tvalid))
      wsdev(t,z) = stddev(tmp(tvalid))
      delete([/tvalid,tmp/])
    else
      delete([/tvalid,tmp/])
      continue
    end if
    ;;print(timew)
  end do
end do
printMinMax(wcomp,0)
printMinMax(wsdev,0)
printMinMax(wnpts,0)

; Plot a three panel plot of the above wind composite
twks = gsn_open_wks("png","composite_"+vers+"_"+bm+"_"+windcomp)
;twks = gsn_open_wks("png","composite_raw_"+windcomp)
;twks = gsn_open_wks("png","composite_filter_"+windcomp)
;twks = gsn_open_wks("png","composite_turb_"+windcomp)

; RESOURCES
;gsn_define_colormap(pwks,"rainbow+gray")
tres = True
tres@gsnMaximize = False
tres@gsnFrame = False
tres@gsnDraw = False
tres@cnFillMode = "RasterFill"
tres@cnFillOn = True
tres@cnLineLabelsOn = False
tres@cnLinesOn = False
tres@vpYF = 0.95 ; THREE TOP
tres@vpHeightF = 0.25 ; THREE PANELS
;tres@vpYF = 0.97 ; FOUR TOP
;tres@vpHeightF = 0.18 ; FOUR PANELS
tres@vpWidthF = 0.7
tres@vpXF = 0.15
tres@cnLevelSelectionMode = "ExplicitLevels"
tres@lbLabelBarOn = True
tres@cnInfoLabelOn = False
tres@tmXTOn = False
tres@tmYROn = False
tres@gsnLeftStringFontHeightF = 0.012
tres@gsnRightStringFontHeightF = 0.012
if bm.eq."monsoon" then
  tres@gsnLeftString = prettyPrint(unix_time(begmonsoon),"ymdhm")
  tres@gsnRightString = prettyPrint(unix_time(endmonsoon),"ymdhm")
else
  tres@gsnLeftString = prettyPrint(unix_time(begbreak),"ymdhm")
  tres@gsnRightString = prettyPrint(unix_time(endbreak),"ymdhm")
end if
tres@tiXAxisFontHeightF = 0.012
;;if daynum.lt.0 then
;;  tres@tmXBMode = "Explicit"
;;  tres@tmXBValues = daybeg
;;  tres@tmXBLabels = tostring(doy)
;;  tres@tmXBLabelFontHeightF = 0.01
;;  tres@tmXBLabelAngleF = -90.0
;;  tres@tmXBLabelJust = "CenterCenter"
;;else
tres@tmXBLabelFontHeightF = 0.01
;;end if
tres@tmYLMode = "Explicit"
tres@tmYLValues = (/0,20,40,60,80,100,120/)
tres@tmYLLabels = tostring(tres@tmYLValues/10)
tres@tmYLLabelFontHeightF = 0.01
tres@trYMinF = 0.0
tres@tiYAxisString = "Height (km)"
tres@tiYAxisFontHeightF = 0.01
if windcomp.eq."w" then
  tres@cnLevels = (/-0.3,-0.2,-0.1,0.0,0.1,0.2,0.3/)
  tres@lbLabelStrings = (/"","-0.3","-0.2","-0.1","0.0","0.1","0.2","0.3",""/)
  tres@lbTitleString = "50 MHz w' (m/s)"
end if
if windcomp.eq."u" .or. windcomp.eq."v" then
  tres@cnLevels = (/-10.0,-8.0,-6.0,-4.0,-2.0,0.0,2.0,4.0,6.0,8.0,10.0/)
  tres@lbLabelStrings = (/"","-10.0","-8.0","-6.0","-4.0","-2.0","0.0","2.0","4.0","6.0","8.0","10.0",""/)
  tres@lbTitleString = "50 MHz u' (m/s)"
end if
tres@cnFillPalette = "ncl_default"
tres@lbOrientation = "vertical"
tres@lbLeftMarginF = 0.30
tres@lbRightMarginF = 0.0
tres@lbTitleFontHeightF = 0.010
tres@lbLabelFontHeightF = 0.008
tres@lbTitlePosition = "Right"
tres@lbTitleDirection = "Across"
tres@lbTitleAngleF = 90.0
tres@lbTitleOffsetF = 0.3
tres@pmLabelBarOrthogonalPosF = 0.0
tres@pmLabelBarWidthF = 0.07
tres@pmLabelBarSide = "Right"
tres@lbLabelAlignment = "ExternalEdges"
tres@tiMainOffsetYF = -0.016
if bm.eq."monsoon" then
  tres@tiMainString = str_upper(bm)+" ("+sprinti("%.2i",toint(ndayssoon))+" DAYS)"
else
  tres@tiMainString = str_upper(bm)+" ("+sprinti("%.2i",toint(ndaysbreak))+" DAYS)"
end if
tres@tiMainFontHeightF = 0.012

; PLOTS
t12 = gsn_csm_contour(twks,wcomp(height|0:120,time|:),tres)
draw(t12)
tres@vpYF = 0.64 ; THREE MIDDLE
;tres@vpYF = 0.73 ; FOUR MIDDLE TOP
tres@gsnLeftString = ""
tres@gsnRightString = ""
tres@tiMainString = ""
delete(tres@cnLevels)
delete(tres@lbLabelStrings)
if windcomp.eq."w" then
  tres@cnLevels = (/0.0,0.1,0.2,0.3,0.4,0.5/)
  tres@lbLabelStrings = (/"","0.0","0.1","0.2","0.3","0.4","0.5",""/)
  tres@lbTitleString = "50 MHz w' (m/s)"
end if
if windcomp.eq."u" .or. windcomp.eq."v" then
  tres@cnLevels = (/0.0,2.0,4.0,6.0,8.0,10.0/)
  tres@lbLabelStrings = (/"","0.0","2.0","4.0","6.0","8.0","10.0",""/)
  tres@lbTitleString = "50 MHz u' (m/s)"
end if
t22 = gsn_csm_contour(twks,wsdev(height|0:120,time|:),tres)
draw(t22)
tres@vpYF = 0.33 ; THREE BOTTOM
;tres@vpYF = 0.49 ; FOUR MIDDLE BOTTOM
delete(tres@cnLevels)
delete(tres@lbLabelStrings)
if bm.eq."monsoon" then
  tres@cnLevels = ispan(0,ndayssoon-1,1)
  labs = new((/dimsizes(tres@cnLevels)+2/),string)
  labs(0) = ""
  labs(1:ndayssoon) = tostring(tres@cnLevels)
  labs(dimsizes(labs)-1) = ""
  tres@lbLabelStrings = labs
  ;tres@cnLevels = (/0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18/)
  ;tres@lbLabelStrings = (/"","0","1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18",""/)
else
  tres@cnLevels = ispan(0,ndaysbreak-1,1)
  labs = new((/dimsizes(tres@cnLevels)+2/),string)
  labs(0) = ""
  labs(1:ndaysbreak) = tostring(tres@cnLevels)
  labs(dimsizes(labs)-1) = ""
  tres@lbLabelStrings = labs
  ;tres@cnLevels = (/0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21/)
  ;tres@lbLabelStrings = (/"","0","1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21",""/)
end if
tres@lbTitleString = "Count"
tres@tiXAxisString = "Time (minutes)"
t32 = gsn_csm_contour(twks,wnpts(height|0:120,time|:),tres)
draw(t32)
frame(twks)
