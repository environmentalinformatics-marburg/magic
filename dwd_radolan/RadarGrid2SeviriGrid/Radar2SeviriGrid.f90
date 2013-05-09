!#########################################################################################
!!  COMPILE
!!  gfortran Radar2SeviriGrid.f90 -o Radar2SeviriGrid.x

!!
!!  USAGE
!!
!!
!!  PURPOSE 
!!  Radar2SeviriGrid
!!
!!  CONTACT
!!  Please send any comments, suggestions, criticism, or (for our sake) bug reports to
!!  
!!
!!
!!  Copyright (c) 2010
!!  Meike Kuehnlein
!!
!!  This program is free software without any warranty and without even the implied 
!!  warranty of merchantability or fitness for a particular purpose.
!!  If you use the software you must acknowledge the software and its author.
!!
!#########################################################################################

PROGRAM Radar2SeviriGrid


  IMPLICIT NONE


  CHARACTER(LEN=300) :: chFileInput
  CHARACTER(LEN=12) :: chDateInput


  LOGICAL(4) :: bError      !! Error indicator
  INTEGER :: x,y

  INTEGER :: i

  INTEGER(2), ALLOCATABLE :: prgiRadarInput(:,:)
  REAL, ALLOCATABLE :: prgfPixelID(:,:)
  REAL, ALLOCATABLE :: prgfRadarOutput(:,:)

  INTEGER :: liCols !! Number of columns in binary input files
  INTEGER :: liRows !! Number of rows in binary input files
  INTEGER :: liColsSeviri !! Number of columns in binary input files
  INTEGER :: liRowsSeviri !! Number of rows in binary input files
  INTEGER(4) :: liRecl


  REAL :: prgfRadarSum
  REAL:: prgfRadarMean
  INTEGER :: prgiRadarCounter
  INTEGER :: x_seviri, y_seviri
  INTEGER :: missingValue
  INTEGER(2) ::  iDatatype       !! Datatype of Idrisi file (1:byte 2:integer*2 4:real*4)
  INTEGER :: prgiPixAnz
  REAL :: prgfPixelIDord(40000)
  INTEGER :: error,z

!   Set parameters
    bError = .FALSE.



!****************************************************************************************
!
!   Read command line arguments
!
!******************************************************************************************
    PRINT *, 'READ ARGUMENTS FROM COMMAND LINE'

!   Name for the input file
    CALL GETARG(1,chFileInput)
     if(chFileInput.eq.'') then
      print*, 'No input file given <name>.'
      bError=.TRUE.
     endif

!   input date
    CALL GETARG(2,chDateInput)
     if(chDateInput.eq.'') then
      print*, 'No date given <name>.'
      bError=.TRUE.
     endif


!*******************************************************************************
!
!   Allocate and initialize arrays
!
!*******************************************************************************
     liCols=900
     liRows=900
     liColsSeviri=250
     liRowsSeviri=170
     liRecl = liCols*liRows

!    Allocate arrays
     allocate( &
     prgiRadarInput(liCols,liRows), &
     prgfPixelID(liCols, liRows), &
     prgfRadarOutput(liColsSeviri,liRowsSeviri))


!    Initialize arrays
     prgiRadarInput = -99.0
     prgfPixelID = -99.0
     prgfRadarOutput = -99.0
     prgfPixelIDord = -99.0


!******************************************************************************* 
!
!   Reading input files
!
!******************************************************************************* 


    print*, 'Reading input files ...'

    OPEN(501,FILE=TRIM(chFileInput), access='direct',recl=liRecl*2)
    READ(501,rec=1) prgiRadarInput
    close(501)


    OPEN(501,FILE='Radar2SeviriGrid_mask.rst', access='direct',recl=liRecl*4)
    READ(501,rec=1) prgfPixelID
    close(501)


!******************************************************************************* 
!
!    Radar to SEVIRI grid
!
!******************************************************************************* 


    print*, 'Radar to SEVIRI grid ...'


     DO i=2000,40000

	prgfRadarSum = 0
	prgiRadarCounter = 0
	prgfRadarMean = 0
	missingValue = 0
	
	DO x=1, liCols
	  DO y=1, liRows

	  IF(prgfPixelID(x,y).eq.i.AND.prgiRadarInput(x,y).ge.0) THEN
	    !PRINT *, 'PixelID: ',prgfPixelID(x,y), i
	    prgfRadarSum = prgfRadarSum + prgiRadarInput(x,y)/10  
	    prgiRadarCounter = prgiRadarCounter + 1
	    !PRINT *, 'Counter/Sum: ',x,y,prgiRadarCounter, prgiRadarInput(x,y), prgfRadarSum

	  ELSEIF(prgfPixelID(x,y).eq.i.AND.prgiRadarInput(x,y).lt.0) THEN
	    missingValue = -99
	  ENDIF
		

	  ENDDO
	ENDDO

	IF(prgiRadarCounter.gt.0.AND.missingValue.eq.0) THEN

	prgfRadarMean = prgfRadarSum/prgiRadarCounter
	!PRINT *, prgfRadarMean	
	y_seviri = i/250
	x_seviri = i-(y_seviri*250)
	!PRINT *, x_seviri, y_seviri

	prgfRadarOutput(x_seviri,y_seviri) = prgfRadarMean
	!PRINT *,'*****************'

	ENDIF

     ENDDO



!******************************************************************************* 
!
!    Writing
!
!******************************************************************************* 
     print*, 'Writing radolan to SEVIRI grid'


     OPEN(501,FILE=TRIM(chDateInput)//'_radolan_SGrid.rst',access='direct',&
	recl=liColsSeviri*liRowsSeviri*4,status='replace')
     WRITE(501,rec=1) prgfRadarOutput
     CLOSE(501)

!	Write Metadata file
	 iDatatype=4
         call FWWriteIdrisiMetadata &  
         ('lnx',TRIM(chDateInput)//'_radolan_SGrid.rdc','radolan mm/h seviri-grid',&               
          iDatatype,liColsSeviri,liRowsSeviri, &                         
         'plane',0.,REAL(liColsSeviri),0.,REAL(liRowsSeviri), & 
          REAL(minval(prgfRadarOutput)),REAL(maxval(prgfRadarOutput)))

    print*, '   '
    print*, '   '

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




