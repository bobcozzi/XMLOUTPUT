           ctl-opt dftactgrp(*NO);

           // ------------------------------------------------------
           // How to generate XML and then save that XML content
           // to the IFS as an ASCII text file.
           // ------------------------------------------------------

           dcl-s  content  SQLTYPE(CLOB:65532);
           dcl-s  start    int(10) INZ(1);
           dcl-s  ifsXMLFile varchar(1024) INZ('/home/<USRPRF>/DEMO.XML');
           dcl-s  ifsUser  varchar(10) INZ(*USER);

           dcl-s parentNode varchar(16) inz('CUSTOMERS>');

           exec SQL SET OPTION commit=*NONE, NAMING=*SYS;
            *INLR = *ON;

            EXEC SQL DECLARE XC CURSOR for
               SELECT
                 xmlrow(
                    cusnum as "CUSNUM",
                    TRIM(LSTNAM) as "LASTNAME",
                    TRIM(INIT) as "INIT",
                    TRIM(street) as "ADDRESS",
                    CITY as "CITY",
                    STATE as "STATE",
                    cast(digits(ZIPCOD) as varchar(6)) as "ZIPCODE"
                  OPTION ROW "CUSTOMER" )
              FROM QIWS.QCUSTCDT;

             EXEC SQL OPEN XC;

               // Read XML into a CLOB or you'll have a learning experience.
             EXEC SQL FETCH XC INTO :content;

             if (SQLState < '02000');
             ifsXMLFile  = %SCANRPL('<USRPRF>' : %TrimR(ifsUser) : ifsXMLFile);
                // write out the starting/opening node to the IFS file

                // Note: If you are running IBM i v7r4 or later,
                //       or V7R3 with a recent TR level, you are be able
                //       to use the IBM-supplied QSYS2.IFS_WRITE_UTF8 instead
                //       of SQLTOOLS.IFS_WRITE although there's no differnce.

               // EXEC SQL call QSYS2.IFS_WRITE_UTF8(
               EXEC SQL call SQLTOOLS.IFS_WRITE(
                                            :ifsXMLFile,
                                            '<' concat :parentNode
                                               );
               DOW (SQLState < '02000');
                  // XMLROW returns, via RPG IV SQL FETCH the <?xml...?> tag for each row.
                  // We don't want that, so skip past it using POSITION and SUBSTR
                 EXEC SQL VALUES POSITION('<CUSTOMER>', :content) INTO :START;
                 
                 // EXEC SQL call QSYS2.IFS_WRITE_UTF8(
                 EXEC SQL call SQLTOOLS.IFS_WRITE(
                                            :ifsXMLFile,
                                                    substr(:content,:start));
                 EXEC SQL FETCH XC INTO :content;
               enddo;
                // write out the ending/closing node to the IFS file
               // EXEC SQL call QSYS2.IFS_WRITE_UTF8(
               EXEC SQL call SQLTOOLS.IFS_WRITE(
                                            :ifsXMLFile,
                                                   '</' concat :parentNode );
             endif;
             EXEC SQL CLOSE XC; 
