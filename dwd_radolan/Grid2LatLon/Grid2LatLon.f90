!#########################################################################################
!!
!!  NAME
!!  Program "Grid2LatLon"
!!
!!
!!  VERSION
!!  $Revision: 1.1.1.1 $
!!
!!
!!  PURPOSE
!!  Compute latitude and longitude files for given projections, corner coordinates and
!!  resolution.
!!
!!
!!  PROCEDURE
!!  1. Compute latitude and longitude values.
!!  2. Store values in Idrisi files.
!!
!!
!!  ADDITIONAL REQUIREMENTS
!!  1. Library FWTools available at info@lcrs.de.
!!  2. Module Grid2LatLon_Global
!!
!!
!!  ATTENTION
!!  - none
!!
!!
!!  CALLING SEQUENCE
!!  gfortran Grid2LatLon.f90 -o Grid2LatLon.x
!!
!!
!!  COMMENT
!!  Inversion formulas are taken from
!!  LANGUAGE
!!  FORTRAN 90/95
!!
!!  CONTACT
!!  Please send any comments, suggestions, criticism, or (for our sake) bug reports to
!!  kuehnlei@staff.uni-marburg.de 
!!
!!
!!  Copyright (c) 2012	
!!  Meike Kühnlein
!!
!!  This program is free software without any warranty and without even the implied 
!!  warranty of merchantability or fitness for a particular purpose.
!!  If you use the software you must acknowledge the software and its author.
!!
!!
!!  HISTORY
!!  $Log: Grid2LatLon.f90,v $
!!  Revision 1.1.1.1  2004/09/21 10:50:07  nauss
!!  Computes latitude and longitude Idrisi files for given
!!  - corner coordinates
!!  - reference system
!!  - grid size.
!!
!!
!#########################################################################################

    program Grid2LatLon

    IMPLICIT NONE


!*****************************************************************************************
!
!	Declaration of variables
!
!*****************************************************************************************

    logical(4) :: bUserSettings             !! Read settings from namelist (1)
                                            !! or from Idrisi rdc file (0)
    logical(4) :: bClarEllipsoid            !! Use Clar ellipsoid
    logical(4) :: bUTM                      !! UMT projection
    logical(4) :: bPolarStereographicCircle !! Polar stereographic projection with one true altitude

    character(7) :: chRefSystem     !! Reference system

    character(50) :: chEllipsoid               !! Ellipsoid: "Clar", "International"

    character(300) :: chInDirectory     !! Input directory
    character(300) :: chOutDirectory    !! Output directory
    character(300) :: chTempDirectory   !! Temporary directory
    character(300) :: chInputWildcard   !! Directory path and file wildcard for infiles
    character(300) :: chInFile          !! Name of the input file
    character(300) :: chFilename        !! Filename of output file
    character(300) :: chControlFile     !! Name of the control file
    character(300) :: chLatFile         !! Latitude file
    character(300) :: chLonFile         !! Longitude file

    character(300),dimension(300) :: rgchInputFiles !! Names of input files

    integer(2) :: iActualFile       !! Counter for actual position in infile array
    integer(2) :: iNumberOfFiles    !! Number of input files
    integer(2) :: iFileCounter      !! File counter
    integer(2) :: iIndex            !! Position of a substring within a string
    integer(2) :: iStatus           !! Necessary for FWArgument routine
    integer(2) :: iDatatype         !! Datatype of binary file
    
    integer(4) :: liCols            !! Number of columns
    integer(4) :: liRows            !! Number of rows
    integer(4) :: liPixel           !! Number of pixels
    integer(4) :: liReclByte        !! Recordlength of binary character*1 files
    integer(4) :: liReclInteger     !! Recordlength of binary integer*2 files
    integer(4) :: liReclReal        !! Recordlength of binary real*4 files
    integer(4) :: liCol !! Counter for input columns
    integer(4) :: liRow !! Counter for input rows
    

    real(4) :: fEast        !! East (x) coordinate
    real(4) :: fNorth       !! North (y) coordinate
    real(4) :: fLat         !! Latitude
    real(4) :: fLon         !! Longitude
    real(4) :: fUTMZone     !! UTM Zone
    real(4) :: fPhiC        !! True altitude
    real(4) :: fLambda0     !! Central longitude
    real(4) :: fLLRefMinX     !! Minimum X coordinate of scene (east>0, west<0)
    real(4) :: fLLRefMaxX     !! Maximum X coordinate of scene (east>0, west<0)
    real(4) :: fLLRefMinY     !! Minimum Y coordinate of scene (north>0, south<0)
    real(4) :: fLLRefMaxY     !! Maximum Y coordinate of scene (north>0, south<0)
    real(4) :: fRefMinX     !! Minimum X coordinate of scene (east>0, west<0)
    real(4) :: fRefMaxX     !! Maximum X coordinate of scene (east>0, west<0)
    real(4) :: fRefMinY     !! Minimum Y coordinate of scene (north>0, south<0)
    real(4) :: fRefMaxY     !! Maximum Y coordinate of scene (north>0, south<0)
    real(4) :: fMinValue    !! Minimum pixel value
    real(4) :: fMaxValue    !! Maximum pixel value
    real(4) :: fMapGrid     !! Map grid
    
    real(4),allocatable :: prgfLat(:,:) !! Array for optical thickness
    real(4),allocatable :: prgfLon(:,:) !! Array for effective radius
    real(4),allocatable :: prgfLatPS(:,:) !! Array for optical thickness
    real(4),allocatable :: prgfLonPS(:,:) !! Array for effective radius

    real(4) :: lambda0
    real(4) :: phi0
    real(4) :: lambdaM
    real(4) :: phiM
    real(4) :: lambdaPS
    real(4) :: phiPS
    real(4) :: lambdaLL    
    real(4) :: phiLL
    real(4) :: x,y,M,R,lat,lon
    real(4) :: xMin, xMax, yMin, yMax



!*****************************************************************************************
!
!	Allocate data arrays
!
!*****************************************************************************************

    liCols=900
    liRows=900
    iDatatype=4

    Allocate ( &
    prgfLat(liCols,liRows), &
    prgfLon(liCols,liRows), &
    prgfLatPS(liCols,liRows), &
    prgfLonPS(liCols,liRows) &
    )


!*****************************************************************************************
!
!	Calculate polarstereographic coodinates of the edges
!
!*****************************************************************************************


	! Input
	lon = 9.0 !lambda
	lat = 51.0 !phi

	lon = 2.0715
	lat = 54.5877

	lon = 15.7208
	lat = 54.7405

	lon = 3.5889
	lat = 46.9526

	lon = 14.6209
	lat = 47.0705

	! set
	R = 6370.04
	lambda0 = 10*(3.14159265/180)
	phi0 = 60*(3.14159265/180)
	lambdaM = lon*(3.14159265/180)
	phiM = lat*(3.14159265/180)


	! ----------------------------------------------------------
	! lambda/phi latlon 2 polarstereographic
	! ----------------------------------------------------------

	! stereographischer Skalierungsfaktor
	M = (1+sin(phi0))/(1+sin(phiM))
	
	! lambda
	lambdaPS = R * M * cos(phiM) * sin(lambdaM-lambda0)
	!print *,'lambdaPS:', lambdaPS

	! phi
	phiPS = -R * M * cos(phiM) * cos(lambdaM-Lambda0)
	!print *,'phiPS:', phiPS


	! ----------------------------------------------------------
	! lambda/phi polarstereographic 2 latlon  
	! ----------------------------------------------------------

	! lambda 
	lambdaLL = atan(-lambdaPS/phiPS) + lambda0
        lambdaLL = lambdaLL*(180/3.14159265) ! Umrechnung in Gradmaß
	!print *,'lambdaLL:', lambdaLL

	! phi
        phiLL = asin((((R ** 2)*(1+sin(phi0))**2)-(lambdaPS**2 + phiPS**2))/&
		     (((R ** 2)*(1+sin(phi0))**2)+(lambdaPS**2 + phiPS**2)))
        phiLL = phiLL*(180/3.14159265) ! Umrechnung in Gradmaß
	!print *,'phiLL:', phiLL



    
! Mittelpunkt
! lambdaLL:   9.0000000    lambdaPS:  -73.462128 
! phiLL:      51.000000       phiPS:  -4208.6450
 
! linke obere Ecke    
! lambdaLL:   2.0714998   lambdaPS:  -523.46094   
! phiLL:      54.587704      phiPS:  -3758.6460

! rechte obere Ecke   
! lambdaLL:   15.720799   lambdaPS:   376.54132   
! phiLL:      54.740498      phiPS:  -3758.6497   
  
! linke untere Ecke 
! lambdaLL:   3.5889001   lambdaPS:  -523.46429    
! phiLL:     46.952595       phiPS:  -4658.6421  

! rechte untere Ecke
! lambdaLL:   14.620898    lambdaPS:   376.53577   
! phiLL:   47.070496 	     phiPS:  -4658.6416    

!*****************************************************************************************
!
!	Calculate map grid polarstereographic
!
!*****************************************************************************************

!  WRITE LONGITUDE
xMin=-523.462
xMax=376.64 

yMin=-4658.6419
yMax=-3758.648


	  xMin = xMin + 0.5
	  yMax = yMax - 0.5

!   Calculate map grid polarstereographic

	do liCol = 1, liCols

	  IF(liCol.gt.1) THEN
	  xMin = xMin + 1.0
	  ENDIF

	  do liRow = 1, liRows
	  prgfLonPS(liCol,liRow) = xMin

	  enddo
	enddo


	do liRow = 1, liRows

	  IF(liRow.gt.1) THEN
	  yMax = yMax - 1.0
	  ENDIF

          do liCol = 1, liCols
	  prgfLatPS(liCol,liRow) = yMax

	 enddo
	enddo

        !PRINT *, prgfLonPS(1,1),prgfLonPS(900,900)
	!PRINT *, prgfLatPS(1,1),prgfLatPS(900,900)

!*****************************************************************************************

!	Write latitude/longitude to output files

!*****************************************************************************************

	open(501,file="longitude_polarstereo.rst",access='direct',recl=liCols*liRows*4)
	write(501,rec=1) prgfLonPS
	close(501)

	open(501,file="latitude_polarstereo.rst",access='direct',recl=liCols*liRows*4)
	write(501,rec=1) prgfLatPS
	close(501)



!	Write Metadata file
    call FWWriteIdrisiMetadata &  
         ('win','longitude_polarstereo.rdc','Longitude', &               
          iDatatype,liCols,liRows, &                         
          chRefSystem,XMin,XMax,YMin,YMax, & 
          minVal(prgfLonPS),maxVal(prgfLonPS))                        

    call FWWriteIdrisiMetadata &  
         ('win','latitude_polarstereo.rdc','Latitde', &               
          iDatatype,liCols,liRows, &                         
          chRefSystem,XMin,XMax,YMin,YMax, & 
          minVal(prgfLatPS),maxVal(prgfLatPS))                        


!*****************************************************************************************
!
!	Transform map grid polarstereographic 2 latlon
!
!*****************************************************************************************
	! ----------------------------------------------------------
	! lambda/phi polarstereographic 2 latlon  
	! ----------------------------------------------------------


	do liCol = 1, liCols
	  do liRow = 1, liRows

	  ! lambda 
          lambdaPS = prgfLonPS(liCol,liRow)
	  phiPS = prgfLatPS(liCol,liRow)

	  lambdaLL = atan(-lambdaPS/phiPS) + lambda0
          lambdaLL = lambdaLL*(180/3.14159265) ! Umrechnung in Gradmaß
	  !print *,'lambdaLL:', lambdaLL
	  
	  prgfLon(liCol,liRow) = lambdaLL

	  enddo
	enddo


	do liCol = 1, liCols
	  do liRow = 1, liRows

          lambdaPS = prgfLonPS(liCol,liRow)
	  phiPS = prgfLatPS(liCol,liRow)
	
	  ! phi
          phiLL = asin((((R ** 2)*(1+sin(phi0))**2)-(lambdaPS**2 + phiPS**2))/&
		     (((R ** 2)*(1+sin(phi0))**2)+(lambdaPS**2 + phiPS**2)))
          phiLL = phiLL*(180/3.14159265) ! Umrechnung in Gradmaß
	  !print *,'phiLL:', phiLL

	  prgfLat(liCol,liRow) = phiLL

	  enddo
	enddo

!*****************************************************************************************

!	Write latitude/longitude to output files

!*****************************************************************************************

	open(501,file="longitude_latlon.rst",access='direct',recl=liCols*liRows*4)
	write(501,rec=1) prgfLon
	close(501)

	open(501,file="latitude_latlon.rst",access='direct',recl=liCols*liRows*4)
	write(501,rec=1) prgfLat
	close(501)



!	Write Metadata file
    call FWWriteIdrisiMetadata &  
         ('win','longitude_latlon.rdc','Longitude', &               
          iDatatype,liCols,liRows, &                         
          chRefSystem,XMin,XMax,YMin,YMax, & 
          minVal(prgfLon),maxVal(prgfLon))                        

    call FWWriteIdrisiMetadata &  
         ('win','latitude_latlon.rdc','Latitde', &               
          iDatatype,liCols,liRows, &                         
          chRefSystem,XMin,XMax,YMin,YMax, & 
          minVal(prgfLat),maxVal(prgfLat))  

END


!###############################################################################

subroutine  FWWriteIdrisiMetadata &  
     (chOS,chIdrisiFile,chMetadataTitle, &               ! Input
     iDatatype,liCols,liRows, &                         ! Input
     chRefSystem,fRefMinX,fRefMaxX,fRefMinY,fRefMaxY, & ! Input
     fDisMinValue,fDisMaxValue)                         ! Input

  !*****************************************************************************************

  !   Declaration of variables

  !*****************************************************************************************

  implicit none

  logical         ::  bErr            !! error flag

  character(len=1) :: chDirSep        !! directory separator
  character(len=*) :: chOS            !! operating system ('lnx' or 'win')
  character(len=*) ::  chRefSystem     !! Reference system
  character(len=*) ::  chMetadataTitle !! Title of the Idrisi *.rst file
  character(50)    ::  chMetadataTitlePrint !! Title of the Idrisi *.rst file
  character(len=*) ::  chIdrisiFile    !! Idrisi file name (*.rst or *.rdc)
  character(300)   ::  chIdrisiRDCFile !! Idrisi meta data file name (*.rdc)
  character(300)   ::  chIdrisiRSTFile !! Idrisi data file name (*.rst only)

  integer(2)      ::  iDatatype       !! Datatype of Idrisi file (1:byte 2:integer*2 4:real*4)
  integer(2)      ::  iLength         !! Length of a character string
  integer(2)      ::  iLengthTitle    !! Length of metadata file title
  integer(2)      ::  iIndex          !! Position of search item in a character string

  integer(4)      ::  liCols          !! Number of columns
  integer(4)      ::  liRows          !! Number of rows

  real(4)         ::  fRefMinX        !! Minimum reference system value in x direction
  real(4)         ::  fRefMaxX        !! Maximum reference system value in x direction
  real(4)         ::  fRefMinY        !! Minimum reference system value in y direction
  real(4)         ::  fRefMaxY        !! Maximum reference system value in y direction
  real(4)         ::  fMinValue       !! Minimum pixel value
  real(4)         ::  fMaxValue       !! Maximum pixel value
  real(4)         ::  fDisMinValue    !! Minimum pixel value for display
  real(4)         ::  fDisMaxValue    !! Maximum pixel value for display


  !*****************************************************************************************



  !   Format

  !*****************************************************************************************

  ! windows formats
  !   Byte metadata format
950 format('file format : IDRISI Raster A.1',/, &
       'file title  : ',a80,/, &
       'data type   : ',a4,/, &
       'file type   : binary',/, &
       'columns     : ',i8,/, &
       'rows        : ',i8,/, &
       'ref. system : ',a7,/, &
       'ref. units  : m',/, &
       'unit dist.  : 1.0000000',/, &
       'min. X      : ',f16.7,/, &
       'max. X      : ',f16.7,/, &
       'min. Y      : ',f16.7,/, &
       'max. Y      : ',f16.7,/, &
       'pos`n error : unknown',/, &
       'resolution  : unknown',/, &
       'min. value  : ',i8,/, &
       'max. value  : ',i8,/, &
       'display min : ',i8,/, &
       'display max : ',i8,/, &
       'value units : unspecified',/, &
       'value error : unknown',/, &
       'flag value  : none',/, &
       'flag def`n  : none',/, &
       'legend cats : 0')

  !   Integer*2 metadata format
951 format('file format : IDRISI Raster A.1',/, &
       'file title  : ',a80,/, &
       'data type   : ',a7,/, &
       'file type   : binary',/, &
       'columns     : ',i8,/, &
       'rows        : ',i8,/, &
       'ref. system : ',a7,/, &
       'ref. units  : m',/, &
       'unit dist.  : 1.0000000',/, &
       'min. X      : ',f16.7,/, &
       'max. X      : ',f16.7,/, &
       'min. Y      : ',f16.7,/, &
       'max. Y      : ',f16.7,/, &
       'pos`n error : unknown',/, &
       'resolution  : unknown',/, &
       'min. value  : ',i8,/, &
       'max. value  : ',i8,/, &
       'display min : ',i8,/, &
       'display max : ',i8,/, &
       'value units : unspecified',/, &
       'value error : unknown',/, &
       'flag value  : none',/, &
       'flag def`n  : none',/, &
       'legend cats : 0')

  !   Real*4 metadata format
952 format('file format : IDRISI Raster A.1',/, &
       'file title  : ',a80,/, &
       'data type   : ',a4,/, &
       'file type   : binary',/, &
       'columns     : ',i8,/, &
       'rows        : ',i8,/, &
       'ref. system : ',a7,/, &
       'ref. units  : m',/, &
       'unit dist.  : 1.0000000',/, &
       'min. X      : ',f16.7,/, &
       'max. X      : ',f16.7,/, &
       'min. Y      : ',f16.7,/, &
       'max. Y      : ',f16.7,/, &
       'pos`n error : unknown',/, &
       'resolution  : unknown',/, &
       'min. value  : ',f10.2,/, &
       'max. value  : ',f10.2,/, &
       'display min : ',f10.2,/, &
       'display max : ',f10.2,/, &
       'value units : unspecified',/, &
       'value error : unknown',/, &
       'flag value  : none',/, &
       'flag def`n  : none',/, &
       'legend cats : 0')

  ! linux formats
  !   Byte metadata format
850 format('file format : IDRISI Raster A.1',a1,/, &
       'file title  : ',a80,a1,/, &
       'data type   : ',a4,a1,/, &
       'file type   : binary',a1,/, &
       'columns     : ',i8,a1,/, &
       'rows        : ',i8,a1,/, &
       'ref. system : ',a7,a1,/, &
       'ref. units  : m',a1,/, &
       'unit dist.  : 1.0000000',a1,/, &
       'min. X      : ',f16.7,a1,/, &
       'max. X      : ',f16.7,a1,/, &
       'min. Y      : ',f16.7,a1,/, &
       'max. Y      : ',f16.7,a1,/, &
       'pos`n error : unknown',a1,/, &
       'resolution  : unknown',a1,/, &
       'min. value  : ',i8,a1,/, &
       'max. value  : ',i8,a1,/, &
       'display min : ',i8,a1,/, &
       'display max : ',i8,a1,/, &
       'value units : unspecified',a1,/, &
       'value error : unknown',a1,/, &
       'flag value  : none',a1,/, &
       'flag def`n  : none',a1,/, &
       'legend cats : 0',a1)

  !   Integer*2 metadata format
851 format('file format : IDRISI Raster A.1',a1,/, &
       'file title  : ',a80,a1,/, &
       'data type   : ',a7,a1,/, &
       'file type   : binary',a1,/, &
       'columns     : ',i8,a1,/, &
       'rows        : ',i8,a1,/, &
       'ref. system : ',a7,a1,/, &
       'ref. units  : m',a1,/, &
       'unit dist.  : 1.0000000',a1,/, &
       'min. X      : ',f16.7,a1,/, &
       'max. X      : ',f16.7,a1,/, &
       'min. Y      : ',f16.7,a1,/, &
       'max. Y      : ',f16.7,a1,/, &
       'pos`n error : unknown',a1,/, &
       'resolution  : unknown',a1,/, &
       'min. value  : ',i8,a1,/, &
       'max. value  : ',i8,a1,/, &
       'display min : ',i8,a1,/, &
       'display max : ',i8,a1,/, &
       'value units : unspecified',a1,/, &
       'value error : unknown',a1,/, &
       'flag value  : none',a1,/, &
       'flag def`n  : none',a1,/, &
       'legend cats : 0',a1)

  !   Real*4 metadata format
852 format('file format : IDRISI Raster A.1',a1,/, &
       'file title  : ',a80,a1,/, &
       'data type   : ',a4,a1,/, &
       'file type   : binary',a1,/, &
       'columns     : ',i8,a1,/, &
       'rows        : ',i8,a1,/, &
       'ref. system : ',a7,a1,/, &
       'ref. units  : m',a1,/, &
       'unit dist.  : 1.0000000',a1,/, &
       'min. X      : ',f16.7,a1,/, &
       'max. X      : ',f16.7,a1,/, &
       'min. Y      : ',f16.7,a1,/, &
       'max. Y      : ',f16.7,a1,/, &
       'pos`n error : unknown',a1,/, &
       'resolution  : unknown',a1,/, &
       'min. value  : ',f10.2,a1,/, &
       'max. value  : ',f10.2,a1,/, &
       'display min : ',f10.2,a1,/, &
       'display max : ',f10.2,a1,/, &
       'value units : unspecified',a1,/, &
       'value error : unknown',a1,/, &
       'flag value  : none',a1,/, &
       'flag def`n  : none',a1,/, &
       'legend cats : 0',a1)




  !*****************************************************************************************

  !   Write metadata to Idrisi *.rdc file

  !*****************************************************************************************

!   Set directory separator
  if(chOS.EQ.'win') then
     chDirSep = CHAR(92)
  elseif(chOS.EQ.'lnx') then
     chDirSep = CHAR(92)
  else
     bErr = .TRUE.
     return
  endif

  !   Set filename of the actual Idrisi *.rdc file (check for lower/upper letters)
  iIndex = index(chIdrisiFile,'.rdc')
  if(iIndex.eq.0) then
     iIndex = index(chIdrisiFile,'.RDC')
  endif
  if(iIndex.eq.0) then
     iIndex = index(chIdrisiFile,'.rst')
  endif
  if(iIndex.eq.0) then
     iIndex = index(chIdrisiFile,'.RST')
  endif
  if(iIndex.eq.0) then
   chIdrisiRDCFile = trim(chIdrisiFile)//'.rdc'
   chIdrisiRSTFile = trim(chIdrisiFile)//'.rst'
  else
   chIdrisiRDCFile = chIdrisiFile(1:iIndex)//'rdc'
   chIdrisiRSTFile = chIdrisiFile(1:iIndex)//'rst'
  endif 
  !   Set title if not explicitly given
  if(chMetadataTitle.eq.'') then
     iLength = len_trim(chIdrisiRDCFile)
     iIndex = index(chIdrisiRDCFile,chDirSep,BACK=.TRUE.)
     chMetadataTitlePrint = chIdrisiRDCFile(iIndex:iLength)
     iIndex = index(chMetadataTitle,'.rdc')
     chMetadataTitlePrint = chIdrisiRDCFile(1:iIndex-1)
  else
     chMetadataTitlePrint = chMetadataTitle
  endif
   iLengthTitle = len_trim(chMetadataTitle)

  !   Get extreme values and display extrema
  fMinValue = fDisMinValue
  fMaxValue = fDisMaxValue
  if(fDisMinValue.eq.0.and.fDisMaxValue.eq.0) then
     fDisMinValue = fMinValue
     fDisMaxValue = fMaxValue
  endif

  !   Write data to the Idrisi *.rdc file with respect to the data format
  open(500,file=trim(chIdrisiRDCFile))
  !   write windows
  if(chOS.EQ.'win') then
     !   Byte binary
     if(iDatatype.eq.1) then
        write(500,950) &
             chMetadataTitle, &
             'byte', &
             liCols, &
             liRows, &
             chRefSystem, &
             fRefMinX, &
             fRefMaxX, &
             fRefMinY, &
             fRefMaxY, &
             int(fMinValue), &
             int(fMaxValue), &
             int(fDisMinValue), &
             int(fDisMaxValue)

        !   Integer*2 binary
     elseif(iDatatype.eq.2) then
        write(500,951) &
             chMetadataTitle, &
             'integer', &
             liCols, &
             liRows, &
             chRefSystem, &
             fRefMinX, &
             fRefMaxX, &
             fRefMinY, &
             fRefMaxY, &
             int(fMinValue), &
             int(fMaxValue), &
             int(fDisMinValue), &
             int(fDisMaxValue)

        !   Real*4 binary
     else
        write(500,952) &
             chMetadataTitle, &
             'real   ', &
             liCols, &
             liRows, &
             chRefSystem, &
             fRefMinX, &
             fRefMaxX, &
             fRefMinY, &
             fRefMaxY, &
             fMinValue, &
             fMaxValue, &
             fDisMinValue, &
             fDisMaxValue
     end if
     ! write linux
  elseif(chOS.EQ.'lnx') then
     !   Byte binary
     if(iDatatype.eq.1) then
        write(500,850) &
             CHAR(13), &
             chMetadataTitlePrint,CHAR(13), &
             'byte',CHAR(13), &
             CHAR(13), &
             liCols,CHAR(13), &
             liRows,CHAR(13), &
             chRefSystem,CHAR(13), &
             CHAR(13), &
             CHAR(13), &
             fRefMinX,CHAR(13), &
             fRefMaxX,CHAR(13), &
             fRefMinY,CHAR(13), &
             fRefMaxY,CHAR(13), &
             CHAR(13), &
             CHAR(13), &
             int(fMinValue),CHAR(13), &
             int(fMaxValue),CHAR(13), &
             int(fDisMinValue),CHAR(13), &
             int(fDisMaxValue),CHAR(13), &
             CHAR(13), &
             CHAR(13), &
             CHAR(13), &
             CHAR(13), &
             CHAR(13)

        !   Integer*2 binary
     elseif(iDatatype.eq.2) then
        write(500,851) &
             CHAR(13), &
             chMetadataTitlePrint,CHAR(13), &
             'integer',CHAR(13), &
             CHAR(13), &
             liCols,CHAR(13), &
             liRows,CHAR(13), &
             chRefSystem,CHAR(13), &
             CHAR(13), &
             CHAR(13), &
             fRefMinX,CHAR(13), &
             fRefMaxX,CHAR(13), &
             fRefMinY,CHAR(13), &
             fRefMaxY,CHAR(13), &
             CHAR(13), &
             CHAR(13), &
             int(fMinValue),CHAR(13), &
             int(fMaxValue),CHAR(13), &
             int(fDisMinValue),CHAR(13), &
             int(fDisMaxValue),CHAR(13), &
             CHAR(13), &
             CHAR(13), &
             CHAR(13), &
             CHAR(13), &
             CHAR(13)

        !   Real*4 binary
     else
        write(500,852) &
             CHAR(13), &
             chMetadataTitlePrint,CHAR(13), &
             'real   ',CHAR(13), &
             CHAR(13), &
             liCols,CHAR(13), &
             liRows,CHAR(13), &
             chRefSystem,CHAR(13), &
             CHAR(13), &
             CHAR(13), &
             fRefMinX,CHAR(13), &
             fRefMaxX,CHAR(13), &
             fRefMinY,CHAR(13), &
             fRefMaxY,CHAR(13), &
             CHAR(13), &
             CHAR(13), &
             fMinValue,CHAR(13), &
             fMaxValue,CHAR(13), &
             fDisMinValue,CHAR(13), &
             fDisMaxValue,CHAR(13), &
             CHAR(13), &
             CHAR(13), &
             CHAR(13), &
             CHAR(13), &
             CHAR(13)
     end if
  endif

  close(500)

  return

end subroutine FWWriteIdrisiMetadata



