-- following code is taken from https://www.askhareesh.com/2014/08/gl-interface-package-procedure.html
--some code was modified like uncommentating some lines 
-- also process_flag and error_mesage did not exist in staging table as shown
-- in the ctl file for its creation https://www.askhareesh.com/2014/08/control-file-for-gl-interface.html
-- also some of the sample data like JETFORMS for user_je_source_name had to be modified in order for interface to work

CREATE OR REPLACE PACKAGE APPS.XX_GL_INT_PKG IS --This is code block is the package header and initializes the procedures that will be defined later in the body

  PROCEDURE GL_INT_LOG (p_msg IN VARCHAR2); -- this procedure is for logging messages to the outfile primarily for debugging

  PROCEDURE GL_INT_MAIN (errbuf OUT VARCHAR2, retcode OUT VARCHAR2); -- This procedure transfers GL data from TEMP staging table to GL_INTERFACE table after validation

END XX_GL_INT_PKG;


CREATE OR REPLACE package body APPS.XX_GL_INT_PKG is --Here we actually define the logic of how our procedures will work

    procedure GL_INT_LOG(p_msg in varchar2) is
        begin
        fnd_file.put_line(fnd_file.log,p_msg); -- this line just logs the input parameter to the outfile
        end;
        
    procedure GL_INT_MAIN(errbuf out varchar2, retcode out varchar2) is
    --we begin with defining c1 cursor to hold our rows from the staging table
        cursor c1 is select a.rowid row_id,a.* -- we will grab the rowid, and all other columns
        from GL_INTERFACE_TEMP a; -- this is the name of the staging table 
        v_gl_int    gl_interface%rowtype; -- this variable will hold the individual row we will insert into gl_interface later after validation
        v_process_flag    varchar2(10); --this flag will indicate if anything is wrong with our data during validation
        v_error_msg   varchar2(100); -- also used for debugging to give more information on what is wrong with data in particular column 
        v_tot_err_msg   varchar2(1000);-- v_error_msg will be concatenated to this variable to capture the "total" error message
        begin
        GL_INT_LOG('before entering the loop'); -- just to log we have begun looping
        for i in c1 loop -- from here on out i will represent the current row we are on from the cursor c1
            v_error_msg :=null; -- needs to be initialized with a value in order for possible value assignment later. Same logic applies to v_tot_err_msg,v_gl_int
            v_process_flag:='S'; -- by default the flag will be S to indicate success... this may change later if there is problem during validation
            v_tot_err_msg:=null;
            v_gl_int:=null;
            --currency_code validation
                begin
                select currency_code into v_gl_int.currency_code
                                    from fnd_currencies
                                    where currency_code=i.currency_code; -- check the fnd_currencies table's currency_code column where it matches our staging data currency_code value...
                exception
                when no_data_found then -- ...if no match found then 
                    v_process_flag:='E'; -- raise exception flag 
                    v_error_msg  := 'Invalid Currency Code =>'||i.currency_code; -- log this message with the invalid curreny code
                    v_tot_err_msg:= v_tot_err_msg||' '||v_error_msg ; -- concatenate to total error message
                when others then -- ... if anything else goes wrong during validation repeat the same error logging as above
                    v_process_flag:='E';
                    v_error_msg   := ' Exception at Currency Code =>'||i.currency_code;
                    v_tot_err_msg:= v_tot_err_msg||' '||v_error_msg ;
                end;    

                -- !!!! All below validation code blocks have the same logic, just the column and table are different

            --user_je_source_name validation 
            --- the staging data given by default from example source had a value of JETFORMS here which does not exist in my instance, this logging helped me catch this. I changed it to 'Others'
                begin
                    select user_je_source_name into v_gl_int.user_je_source_name
                                                from gl_je_sources
                                                where user_je_source_name=i.user_je_source_name;
                    exception
                    when no_data_found then
                        v_process_flag:='E';
                        v_error_msg  := 'Invalid Sourec Name =>'||i.user_je_source_name;
                        v_tot_err_msg:= v_tot_err_msg||' '||v_error_msg ;
                    when others then
                        v_process_flag:='E';
                        v_error_msg   := ' Exception at Sourec Name =>'||i.user_je_source_name;
                        v_tot_err_msg:= v_tot_err_msg||' '||v_error_msg ;
                    end;    
            --category_name  validation
                    begin
                        select user_je_category_name into v_gl_int.user_je_category_name
                        from gl_je_categories
                        where user_je_category_name=i.user_je_category_name;
                    exception
                    when no_data_found then
                        v_process_flag:='E';
                        v_error_msg  := 'Invalid category_name =>'||i.user_je_category_name;
                        v_tot_err_msg:= v_tot_err_msg||' '||v_error_msg ;
                    when others then
                        v_process_flag:='E';
                        v_error_msg   := ' Exception at category_name =>'||i.user_je_category_name;
                        v_tot_err_msg:= v_tot_err_msg||' '||v_error_msg ;  
                    end;
            --user id validation
                    begin
                            select user_id into v_gl_int.created_by from fnd_user
                                        where  user_id = i.created_by;
                        exception
                        when no_data_found then
                            v_process_flag:='E';
                            v_error_msg  := 'Invalid user id =>'||i.created_by;
                            v_tot_err_msg:= v_tot_err_msg||' '||v_error_msg ;
                        when others then
                            v_process_flag:='E';
                            v_error_msg   := ' Exception at user id =>'||i.created_by;
                            v_tot_err_msg:= v_tot_err_msg||' '||v_error_msg ;
                    end;
            -- set of books id validation
                    begin
                    SELECT SET_OF_BOOKS_ID INTO v_gl_int.set_of_books_id
                            FROM GL_SETS_OF_BOOKS WHERE SET_OF_BOOKS_ID=i.set_of_books_id;
                        exception
                        when no_data_found then
                            v_process_flag:='E';
                            v_error_msg  := 'Invalid set of books id =>'||i.set_of_books_id;
                            v_tot_err_msg:= v_tot_err_msg||' '||v_error_msg ;
                        when others then
                            v_process_flag:='E';
                            v_error_msg   := ' Exception atset of books id =>'||i.set_of_books_id;
                            v_tot_err_msg:= v_tot_err_msg||' '||v_error_msg ;
                    end;
            
            -- end of Validation


            -- assign the corresponding attributes from i into v_gl_int
            v_gl_int.status:=i.status;
            v_gl_int.set_of_books_id:=i.set_of_books_id;
            v_gl_int.accounting_date:=i.accounting_date;
            v_gl_int.currency_code:=i.currency_code;
            v_gl_int.date_created:=i.date_created;
            v_gl_int.created_by:=i.created_by;
            v_gl_int.actual_flag:=i.actual_flag;
            v_gl_int.user_je_category_name:=i.user_je_category_name;
            v_gl_int.user_je_source_name:=i.user_je_source_name;
            v_gl_int.segment1:=i.segment1;
            v_gl_int.segment2:=i.segment2;
            v_gl_int.segment3:=i.segment3;
            v_gl_int.segment4:=i.segment4;
            v_gl_int.segment5:=i.segment5;
            v_gl_int.entered_dr:=i.entered_dr;
            v_gl_int.entered_cr:=i.entered_cr;
            v_gl_int.accounted_dr:=i.accounted_dr;
            v_gl_int.accounted_cr:=i.accounted_cr;
            v_gl_int.group_id:=i.group_id;
            GL_INT_LOG('before inserting the loop'); -- 
            if v_process_flag = 'S' then    -- if no exception occured during this particular rows validation then...
                insert into gl_interface values v_gl_int; -- .. insert this rows data into gl_interface
            end if;
            update GL_INTERFACE_TEMP set -- no matter what (exception or not)
                process_flag=v_process_flag, -- on the staging table, set the process_flag column's value to current flag value
                error_message=v_tot_err_msg -- and error_message 
                where rowid=i.row_id; --on this particular row. rowid increases performance since it does not scan entire table
            GL_INT_LOG('after inserting the loop');    
        end loop;
        exception
        when others then -- general catch all exception 
        GL_INT_LOG('exception occured at GL_INT_MAIN loop');
    end GL_INT_MAIN;
 end XX_GL_INT_PKG;