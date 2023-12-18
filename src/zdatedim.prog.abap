REPORT zdatedim.

DATA:
  date_dimension TYPE STANDARD TABLE OF zdatedim,
  dim_line       LIKE LINE OF date_dimension.


SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS:
    p_dat1 TYPE dats OBLIGATORY DEFAULT '20200101',
    p_dat2 TYPE dats OBLIGATORY DEFAULT '20251231',
    p_fcal TYPE tfacd-ident DEFAULT 'HR'.

SELECTION-SCREEN END OF BLOCK b1.

INITIALIZATION.
  %_p_dat1_%_app_%-text   = 'From date'.
  %_p_dat2_%_app_%-text   = 'To date'.
  %_p_fcal_%_app_%-text   = 'Factory Calendar'.


START-OF-SELECTION.

  DATA(start_date) = p_dat1.
  DATA(current_date) = start_date.
  DATA(end_date) = p_dat2 + 1.

  WHILE current_date NE end_date.

    " DATE_ID (20220715)
    dim_line-date_id = current_date.

    " DATE_FIELD
    dim_line-date_field = current_date.

    " DATE_DESC (15.07.2022.) convert to your date format
    dim_line-date_desc = |{ current_date+6(2) }.{ current_date+4(2) }.{ current_date(4) }.|.

    " YEAR_NUM (2022)
    dim_line-year_num = current_date(4).

    "MONTH_NUM (7)
    dim_line-month_num = current_date+4(2).

    "HALF_NUM (2)
    CASE dim_line-month_num.
      WHEN 1 OR 2 OR 3 OR 4 OR 5 OR 6.
        dim_line-half_num = 1.
      WHEN OTHERS.
        dim_line-half_num = 2.
    ENDCASE.

    "QUARTER_NUM (3)
    CASE dim_line-month_num.
      WHEN 1 OR 2 OR 3.
        dim_line-quarter_num = 1.
      WHEN 4 OR 5 OR 6.
        dim_line-quarter_num = 2.
      WHEN 7 OR 8 OR 9.
        dim_line-quarter_num = 3.
      WHEN OTHERS.
        dim_line-quarter_num = 4.
    ENDCASE.

    "WEEK_NUM (28)
    DATA week_in_year TYPE scal-week.

    CALL FUNCTION 'GET_WEEK_INFO_BASED_ON_DATE'
      EXPORTING
        date = current_date
      IMPORTING
        week = week_in_year.
    "MONDAY =
    "SUNDAY =

    dim_line-week_num = week_in_year+4(2).

    "YEAR_QUARTER_NUM (202203)
    dim_line-year_quarter_num = |{ dim_line-year_num }{ CONV string( dim_line-quarter_num ) WIDTH = 2 ALPHA = IN }|.

    "YEAR_MONTH_NUM (202207)
    dim_line-year_month_num = |{ dim_line-year_num }{ CONV string( dim_line-month_num ) WIDTH = 2 ALPHA = IN }|.

    "YEAR_WEEK_NUM (202238)
    dim_line-year_week_num = week_in_year.

    "DAY_MONTH_NUM (15)
    dim_line-day_month_num = |{ current_date+6(2) }|.

    "DAY_WEEK_NUM (1 = Monday, 2 = Tuesday...)
    DATA day_of_week TYPE scal-indicator.

    CALL FUNCTION 'DATE_COMPUTE_DAY'
      EXPORTING
        date = current_date
      IMPORTING
        day  = day_of_week.

    dim_line-day_week_num = day_of_week.

    "DAY_YEAR_NUM (265)
    DATA start_of_year TYPE sy-datum.

    start_of_year = |{ dim_line-year_num }0101|.
    dim_line-day_year_num = current_date - start_of_year + 1.

    "YEAR_DESC (2022)
    dim_line-year_desc = |{ dim_line-year_num }|.

    "YEAR_MONTH_DESC (2022-07)
    dim_line-year_month_desc = |{ dim_line-year_desc }-{ CONV string( dim_line-month_num ) WIDTH = 2 ALPHA = IN }|.

    "YEAR_QUARTER_DESC (2022-03)
    dim_line-year_quarter_desc = |{ dim_line-year_desc }-Q{ dim_line-quarter_num }|.

    "YEAR_WEEK_DESC (2022-W36)
    dim_line-year_week_desc = |{ dim_line-year_desc }-W{ dim_line-week_num }|.

    "QUARTER_DESC (Kvartal 1, Kvartal 2 itd.)
    CASE sy-langu.
      WHEN 'E'. "English
        dim_line-quarter_desc = |Quarter { dim_line-quarter_num }|.
      WHEN '6'. "Croatian
        dim_line-quarter_desc = |Kvartal { dim_line-quarter_num }|.
      WHEN OTHERS. "English
        dim_line-quarter_desc = |Quarter { dim_line-quarter_num }|.
    ENDCASE.



    "MONTH_DESC (Siječanj, Veljača...) -> these function modules work with logon language
    DATA month_name TYPE fcltx.

    CALL FUNCTION '/SAPCE/IURU_GET_MONTH_NAME'
      EXPORTING
        iv_date       = current_date
      IMPORTING
        ev_month_name = month_name.

    dim_line-month_desc = month_name.

    "DAY_DESC
    DATA day_description TYPE langt.

    CALL FUNCTION 'FTR_DAY_GET_TEXT'
      EXPORTING
        pi_date      = current_date
      IMPORTING
        "pe_day_text1=
        pe_day_text2 = day_description.

    dim_line-day_desc = day_description.

    "YEAR_QUARTER_SHORTDESC (22-Q1)
    dim_line-year_quarter_shortdesc = |{ dim_line-year_desc+2(2) }-Q{ dim_line-quarter_num }|.

    "YEAR_MONTH_SHORTDESC (22-07)
    dim_line-year_month_shortdesc = |{ dim_line-year_desc+2(2) }-{ CONV string( dim_line-month_num ) WIDTH = 2 ALPHA = IN }|.

    "QUARTER_YEAR_DESC (Q3-2022)
    dim_line-quarter_year_desc = |Q{ dim_line-quarter_num }-{ dim_line-year_desc }|.

    "MONTH_YEAR_DESC (sij-22)
    dim_line-month_year_desc = |{ month_name(3) }-{ dim_line-year_desc+2(2) }|.

    "FIRST_DATE_OF_MONTH
    dim_line-first_date_of_month = |{ dim_line-year_num }{ CONV string( dim_line-month_num ) WIDTH = 2 ALPHA = IN }01|.

    "LAST_DATE_OF_MONTH
    CALL FUNCTION 'RP_LAST_DAY_OF_MONTHS'
      EXPORTING
        day_in            = current_date
      IMPORTING
        last_day_of_month = dim_line-last_date_of_month.

    "WORKDAY_FLAG
    DATA no_working_day TYPE boole-boole.

    CALL FUNCTION 'BKK_CHECK_HOLIDAY'
      EXPORTING
        i_date            = current_date
        i_calendar1       = p_fcal
      IMPORTING
        e_x_no_workingday = no_working_day.

    IF no_working_day = abap_true.
      dim_line-workday_flag = 0.
    ELSE.
      dim_line-workday_flag = 1.
    ENDIF.

    "WORKDAY_IN_YEAR
    DATA: first_day_of_year TYPE kona-datab,
          working_days      TYPE TABLE OF rke_dat.

    first_day_of_year = |{ dim_line-year_num }0101|.

    CALL FUNCTION 'RKE_SELECT_FACTDAYS_FOR_PERIOD'
      EXPORTING
        i_datab  = first_day_of_year
        i_datbi  = current_date
        i_factid = p_fcal
      TABLES
        eth_dats = working_days.

    dim_line-workday_in_year = lines( working_days ).


    "WEEKEND_FLAG
    IF dim_line-day_week_num = 6 OR dim_line-day_week_num = 7.
      dim_line-weekend_flag = 1.
    ELSE.
      dim_line-weekend_flag = 0.
    ENDIF.

    "DECADE
    IF dim_line-day_month_num < 11.
      dim_line-decade = 1.
    ELSEIF dim_line-day_month_num < 21.
      dim_line-decade = 2.
    ELSE.
      dim_line-decade = 3.
    ENDIF.

    "YEAR_MONTH_WEEK
    dim_line-year_month_week = |{ dim_line-year_month_num }{ dim_line-week_num }|.


    " update database
    MODIFY zdatedim FROM dim_line.


    current_date = current_date + 1.

    CLEAR dim_line.

  ENDWHILE.
