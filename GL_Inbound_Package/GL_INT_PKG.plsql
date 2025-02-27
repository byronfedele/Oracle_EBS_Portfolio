CREATE OR REPLACE PACKAGE APPS.XX_GL_INT_PKG IS

  PROCEDURE GL_INT_LOG (p_msg IN VARCHAR2);

  PROCEDURE GL_INT_MAIN (errbuf OUT VARCHAR2, retcode OUT VARCHAR2);

END XX_GL_INT_PKG;


CREATE OR REPLACE package body APPS.XX_GL_INT_PKG is

    procedure GL_INT_LOG(p_msg in varchar2) is
        begin
        fnd_file.put_line(fnd_file.log,p_msg);
        end;
        
    procedure GL_INT_MAIN(errbuf out varchar2, retcode out varchar2) is
        cursor c1 is select a.rowid row_id,a.* 
        from GL_INTERFACE_TEMP a;
        v_gl_int    gl_interface%rowtype;
        v_process_flag    varchar2(10);
        v_error_msg   varchar2(100);
        v_tot_err_msg   varchar2(1000);
        begin
        GL_INT_LOG('before entering the loop');
        for i in c1 loop
            v_error_msg :=null;
            v_process_flag:='S';
            v_tot_err_msg:=null;
            v_gl_int:=null;
            --currency_code validation
                begin
                select currency_code into v_gl_int.currency_code
                                    from fnd_currencies
                                    where currency_code=i.currency_code;
                exception
                when no_data_found then
                    v_process_flag:='E';
                    v_error_msg  := 'Invalid Currency Code =>'||i.currency_code;
                    v_tot_err_msg:= v_tot_err_msg||' '||v_error_msg ;
                when others then
                    v_process_flag:='E';
                    v_error_msg   := ' Exception at Currency Code =>'||i.currency_code;
                    v_tot_err_msg:= v_tot_err_msg||' '||v_error_msg ;
                end;    

            --user_je_source_name validation
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
            GL_INT_LOG('before inserting the loop');
            if v_process_flag = 'S' then    
                insert into gl_interface values v_gl_int;
            end if;
            update GL_INTERFACE_TEMP set 
                process_flag=v_process_flag,
                error_message=v_tot_err_msg
                where rowid=i.row_id;
            GL_INT_LOG('after inserting the loop');    
        end loop;
        exception
        when others then
        GL_INT_LOG('exception occured at GL_INT_MAIN loop');
    end GL_INT_MAIN;
 end XX_GL_INT_PKG;