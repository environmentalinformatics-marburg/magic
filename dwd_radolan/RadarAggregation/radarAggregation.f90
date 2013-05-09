!###############################################################################
!!
!!  NAME
!!
!!
!!  PURPOSE 
!!  sum over one day
!! 
!!
!!  CALL
!!  gfortran radarAggregation.f90 -o radarAggregation.x
!!	 ./radarAggregation.x
!!
!!
!!
!!
!###############################################################################

    module radarAggregation_defs
 
!******************************************************************************* 
! 
!   Declaration of variables for satwi
! 
!******************************************************************************* 

  !! Command line arguments
  CHARACTER(LEN=12) :: chDateInput    !! Command line 
  CHARACTER(LEN=10) :: chCols    !! Command line argument liCols
  CHARACTER(LEN=10) :: chRows    !! Command line argument for liRows
  CHARACTER(LEN=300) :: chPathInput    !! Command line 


  INTEGER :: liCols
  INTEGER :: liRows
  INTEGER :: liScen
  INTEGER(4) :: liRecl !! Recordlength for satellite data binary input files



  REAL(4),ALLOCATABLE :: prgfRadar(:,:,:)

  CHARACTER(LEN=300) :: chRadar

  REAL(4),ALLOCATABLE :: prgfRadarSum(:,:)

  INTEGER,ALLOCATABLE :: prgiRadarSumAnz(:,:)


  REAL(4),ALLOCATABLE :: prgfRadarTemp(:,:)


  REAL(4) :: A,B,C,D,E,F,G,H,K
  REAL(4) :: A_LWP,B_LWP,C_LWP,D_LWP,E_LWP,F_LWP,G_LWP,H_LWP,K_LWP

  ! Für Subroutine julianday *********************************
  INTEGER :: yyyy ! Jahr
  INTEGER :: mm  ! Monat
  INTEGER :: dd  ! Tag
  REAL :: hh	!Stunde
  REAL :: mi	!Minute
  REAL :: ss	!Sekunden
  REAL(kind=8) :: rjulday
  REAL(kind=8) :: prgfJulDateInput


  REAL(kind=8) :: prgfJulDateScenes(30000)
  CHARACTER(LEN=12) :: chDateScenes(30000)
  INTEGER :: anzdate
  REAL(kind=8) :: prgfTimeMin, prgfTimeMax
  CHARACTER(LEN=12) :: chDate(12)


  logical(4) :: bError      !! Error indicator
  INTEGER :: x,y,istat,i,z

  integer(2)  ::  iDatatype 
  INTEGER :: error,ios

  end module radarAggregation_defs

!###############################################################################


PROGRAM radarAggregation

USE radarAggregation_defs

IMPLICIT NONE


!   Set parameters
    bError = .FALSE.

!******************************************************************************* 
!
!   Read command line parameters
!
!******************************************************************************* 
    PRINT *, 'READ ARGUMENTS FROM COMMAND LINE'

    ! Name for the input file
    CALL GETARG(1,chDateInput)
     if(chDateInput.eq.'') then
      print*, 'No date given <chdate>.'
      bError=.TRUE.
     endif

    ! Name for the input file
    CALL GETARG(2,chPathInput)
     if(chPathInput.eq.'') then
      print*, 'No date given <chdate>.'
      bError=.TRUE.
     endif

!    Number of columns in the input binary dataset
    CALL GETARG(3,chCols)
     if(chCols.eq.'') then 
      print*, 'No coloumns given <cols>.'
      bError=.TRUE.
     else
      read(chCols, *) liCols
     endif

!    Number of rows in the input binary dataset
     CALL GETARG(4, chRows)
     if(chRows.eq.'') then
      print*, 'No rows given <rows>.'
      bError=.TRUE.
     else
     read(chRows, *) liRows
     endif



   PRINT *, '<chDate>:     ', TRIM(chDateInput)


!*******************************************************************************
!
!   Allocate and initialize arrays
!
!*******************************************************************************
     
     liRecl = liCols*liRows
     liScen = 24

!    Allocate arrays
     allocate( &
	prgfRadar(liScen,liCols,liRows),&
	prgfRadarSum(liCols,liRows),&
	prgiRadarSumAnz(liCols,liRows),&
	prgfRadarTemp(liCols,liRows))


!    Initialize arrays
	prgfRadar = -99.0
	prgfRadarSum =  0
	prgiRadarSumAnz =  0
	prgfRadarTemp =  -99.0


!*******************************************************************************
!
!   Find scenes
!
!*******************************************************************************

        ! z.B. 12 Uhr
	! -> 11:45, 12:00, 12:15, 12:30 --> 12:50  
	prgfTimeMin = -0.99
	prgfTimeMax = 0.01


      !print*, ' '
      !print*, 'Find scenes lying within one hour ...'


	   READ (chDateInput(1:4),*) yyyy
	   READ (chDateInput(5:6),*) mm
	   READ (chDateInput(7:8),*) dd
	   READ (chDateInput(9:10),*) hh
	   READ (chDateInput(11:12),*) mi
	   
	   !PRINT *, 'Date:', chDateInput, yyyy,mm,dd,hh,mi
	   CALL julianday	
	   prgfJulDateInput=rjulday-2454467 !01.01.2008


		

      print*, 'Finding satellite scenes...'
      
      istat=0
      OPEN(501,FILE="scenes.dat")
      DO i=1,30000
	 READ(501,*,IOSTAT=istat)chDateScenes(i)
	 IF(istat<0) EXIT
         anzdate=anzdate+1
	 !PRINT *,anzdate, chDateScenes(i)
      ENDDO
      !PRINT *, 'All: ',anzdate
      CLOSE(501)


     DO i=1,anzdate
	   READ (chDateScenes(i)(1:4),*) yyyy
	   READ (chDateScenes(i)(5:6),*) mm
	   READ (chDateScenes(i)(7:8),*) dd
	   READ (chDateScenes(i)(9:10),*) hh
	   READ (chDateScenes(i)(11:12),*) mi
	   
	   !PRINT *, 'Date:', chDateScenes(i)	
	   !PRINT *, yyyy,mm,dd,hh,mi
		
	   CALL julianday
	   prgfJulDateScenes(i)=rjulday-2454467 !01.01.2008
      ENDDO	

     z=0
     DO i=1,anzdate

	IF((prgfJulDateInput-prgfJulDateScenes(i)).gt.prgfTimeMin.AND.&
	   (prgfJulDateInput-prgfJulDateScenes(i)).lt.prgfTimeMax) THEN
 	   z=z+1
	   PRINT *, z,chDateInput,' ',chDateScenes(i)
	   chDate(z)=chDateScenes(i)
	ENDIF

     ENDDO

!*******************************************************************************
!
!   Read satellite data
!
!*******************************************************************************


      print*, 'Reading input satellite scenes...'

      DO i=1, z

       chRadar=TRIM(chPathInput)//TRIM(chDate(i))//"_radolan_SGrid.rst"

       open(501,file=TRIM(chRadar),access='direct',recl=liRecl*4)
       read(501,rec=1) prgfRadar(i,:,:)
       close(501)



      ENDDO

!*******************************************************************************
!
!   Calculate mean over one hour
!
!*******************************************************************************


      print*, 'Calculate sum over one day'


      DO x=1, liCols
	DO y=1, liRows

        !PRINT *, '******* pixel ********'
        DO i=1,z
 	 IF(prgfRadar(i,x,y).ne.-99) THEN
 	   prgfRadarSum(x,y) = prgfRadarSum(x,y) + prgfRadar(i,x,y)
	   prgiRadarSumAnz(x,y) = prgiRadarSumAnz(x,y) + 1
	   !PRINT *, i, prgfRadarSum(x,y), prgfRadar(i,x,y), prgiRadarSumAnz(x,y)
         ENDIF
	ENDDO	

 	IF(prgiRadarSumAnz(x,y).eq.24) prgfRadarTemp(x,y) = prgfRadarSum(x,y)   
	!PRINT *, prgfRadarTemp(x,y)

	ENDDO
      ENDDO
      

!*******************************************************************************
!
!   Writing temporally aggregated data
!
!*******************************************************************************


      print*, 'Writing output ...'

      iDatatype=4 
      open(501,file=chDateInput(1:8)//"_radar_SGrid.rst",&!
 	access='direct',recl=liRecl*4,status='replace')
      WRITE(501,rec=1) prgfRadarTemp
      close(501)

       ! Write Idrisi Metadata
       call FWWriteIdrisiMetadata &  
        ('lnx',chDateInput(1:8)//"_radar_SGrid.rdc","radolan mm/day", &
         iDatatype,liCols,liRows, &
         'plane',0.,REAL(liCols),0.,REAL(liRows), &
         minval(prgfRadarTemp),maxval(prgfRadarTemp))




      print*, ' '

END





!******************************************************************************************************


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

!******************************************************************************************************

      Subroutine julianday
      use radarAggregation_defs
      implicit none

! Zweck: Die Subroutine julianday berchnet das julianische Datum aus einem gregoranischen
!        Datum auf Stunde und Minute genau
! Input: Der Subroutine muss das Jahr yyyy, der Monat mm, der Tag dd, die Stunde hh und
!	 Minute mi übergeben werden.
!        Wenn nötig kann es auch mit Sekunden ergänzt werden.
! Output: Ausgegeben wird das julianische Datum

!    verändert und ergänzt Meike K. 6.1.2007
!
!  ===DOC-Ende==================================================================
!===========================================================
!     Function julday gives the julian day for a given
!     calender date. The julian day is continous daynumber
!     starting at 12:00 Eph.Time on Jan 1 4713 B.C.. 
!     As the Julian day number has its origin in astronomy
!     the day starts at noon!!! The fundamental epoch
!     1900 Jan 0d12h ET has the JDnumber 2415020.0 .
!     This routines is adapted from Numerical Recipes for C
!     1990 ed. It gives the JD starting at noon of the respective
!     day
!
!     Parameters and constants
!     mm    month
!     id    day of the month
!     iyyy  year, all digits have to be given
!

!============================================================
      
! ------Variablen--------------------------------------------

	INTEGER :: julday
	INTEGER, PARAMETER :: igreg =15+31*(10+12*1582) ! igreg starting point of gregorian calendar. Before that
							!           roman calendar dates has to be used.
        INTEGER :: ja	
	INTEGER :: jm
	INTEGER :: jy	!julianisch tag, monat, jahr
	REAL :: hours 

	
!----Testzuweisung--------------------------------------------	
!	yyyy=2006
!	mm=12
!	dd=12
!	hh=10
!	mi=15
!	ss=0
!------------------------------------------------------------

      jy=yyyy

!     ----------- check input -------------
      if (jy.eq.0) then
	 print *,'julday: there is no year zero.'
	 stop 16
      end if
      if (mm.le. 0 .or. mm .gt.12) then
	 print *,'julday: mm out of allowed range:',mm
	 stop 16
      end if
      if (dd.le. 0 .or. dd.gt. 31) then
	 print *,'julday: dd out of allowed range:',dd
	 stop 16
      end if
      
!     --- as there is no year 0:
      IF (jy.lt.0) THEN 
      	jy=jy+1
      END IF
      
!     --- use march as starting point of the year
!     --- to avoid problems with february.  
!     wenn mm>2 belasse yyyy und mm
!     wenn mm=1 oder mm=2 -> yyyy=yyyy-1 mm=mm+12
      
      IF (mm.eq.1.or.mm.eq.2) THEN
      	    jy=jy-1
	    jm=mm+13
      ELSE IF (mm.gt.2) THEN
            jm=mm+1
      ENDIF
      
!     --- an intelligent formula to compute 
!     --- the day of the year

      julday=int(365.25*jy)+int(30.6001*jm)+dd+1720995
      
!     --- the leap years
      if (dd+31*(mm+12*yyyy).ge.igreg) then
        ja=int(0.01*jy)
        julday=julday+2-ja+int(0.25*ja)
      endif
!------------------------------------------------------------- 
!------Berechnung Tagesbruchteil in Dezimalstunden   
       
       rjulday=julday  !Umschreiben in real
       hours = (hh+(mi/60))/24
!       PRINT *,'hours',hours
       rjulday = rjulday + hours

!      PRINT *, rjulday
      
      END SUBROUTINE julianday
