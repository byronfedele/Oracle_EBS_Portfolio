create or replace package body PO_VALID_PKG_BF as -- Changed XX to BF, all instances of XX have been replaced with BF as that is my unique id (assigned in class)
   gn_request_id       NUMBER ; 
   gn_user_id          NUMBER ;
   gn_org_id           NUMBER ;
   gn_organization_id  NUMBER ; 
   gc_val_status       VARCHAR2 ( 10 ) := 'VALIDATED';
   gc_err_status       VARCHAR2 ( 10 ) := 'ERROR';
   gc_new_status       VARCHAR2 ( 10 ) := 'NEW';
   
   Procedure main (p_errbuf  OUT NOCOPY Varchar2,
                   p_retcode OUT NOCOPY Number) is
                   
   Cursor cur_po_order_header -- Cursor keyword just grabs records row by row and assigns it to this "variable" (cur_po_order_header) 
     IS
            SELECT          XPOIS.vendor_number
                          , XPOIS.vendor_id
                          , XPOIS.document_type_code
                          , XPOIS.agent_number
                          , XPOIS.ship_to_location
                          , XPOIS.ship_to_location_id
                          , XPOIS.bill_to_location
                          , XPOIS.bill_to_location_id
                          , XPOIS.curr_code
                    FROM  PURCHASE_ORDERBF_STG  XPOIS -- Changed value here to match my staging table name
                    WHERE UPPER(XPOIS.record_status) = gc_new_status -- grabs records from staging table where value is 'NEW' in record_status column
                    GROUP BY XPOIS.vendor_number
                           , XPOIS.vendor_id
                           , XPOIS.document_type_code
                           , XPOIS.agent_number
                           , XPOIS.ship_to_location
                           , XPOIS.ship_to_location_id
                           , XPOIS.bill_to_location
                           , XPOIS.bill_to_location_id
                           , XPOIS.curr_code  ; 
    -- END OF cur_po_order_header

    Cursor  cur_po_order_lines (
                                 p_vendor_number        IN VARCHAR2
                               , p_ship_to_location     IN VARCHAR2
                               , p_bill_to_location     IN VARCHAR2
                               )
     IS
              SELECT XPOIS.*
                    FROM   PURCHASE_ORDERBF_STG  XPOIS  --<Change value here as well
                    WHERE  XPOIS.vendor_number          = p_vendor_number
                    AND    XPOIS.ship_to_location       = p_ship_to_location
                    AND    XPOIS.bill_to_location       = p_bill_to_location; 
    --END OF cur_po_order_lines

   --Local Variables
     ln_batch_id          Number;
     ln_po_header_id      Number;
     l_curr_code          Number;
     l_error_flag         Number :=0; -- this is the error flag and it is given an initial value of 0. If anything goes wrong later, this value will change as defined in the following code
     l_vendor_id          Number;
     l_agent_id           Number;
     l_agent_name         varchar2(100);
     l_inventory_item_id  number;
     ln_po_line_id        number;
     counter              number:=0;

   begin --Begins MAIN 
        mo_global.init('PO');
        
        mo_global.set_policy_context('S',FND_PROFILE.VALUE('USER_ID')); 
        fnd_file.put_line (fnd_file.output,FND_PROFILE.VALUE('USER_ID'));
        gn_request_id      := FND_GLOBAL.CONC_REQUEST_ID;              
        gn_user_id         := nvl(FND_PROFILE.VALUE('USER_ID'),-1);         
        gn_org_id          := nvl(FND_PROFILE.VALUE('ORG_ID'),204);  
        gn_organization_id := TO_NUMBER (OE_PROFILE.VALUE('SO_ORGANIZATION_ID'));
        --
        --Get Batch ID from standard sequence
        --
        select MSC_ST_BATCH_ID_S.nextval
          into ln_batch_id 
        from   dual; -- dual is a dummy table and not a real table in the DB
        dbms_output.put_line(ln_batch_id );
        
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Batch ID : '||ln_batch_id);
        FND_FILE.PUT_LINE(FND_FILE.output,'Batch ID : '||ln_batch_id);
        for   i in cur_po_order_header loop --LETS call this LOOP A  
                      counter := 0;
                      --Get Interface Header ID from sequence
                      select PO_HEADERS_INTERFACE_S.nextval
                        into ln_po_header_id
                        from dual;             
                      FND_FILE.PUT_LINE(FND_FILE.output,'Header Id : '||ln_po_header_id);
                      
                    begin --Lets Validate Currency Code
                      PO_VALID_PKG_BF.Validate_Currency_BF(i.curr_code,l_curr_code ); -- we define a function later called Validate_Currency_BF, remember we are in a loop and iterating over cur_po_order_header and each row is i
                      if l_curr_code = 2 then -- if the outcome (l_curr_code) of Validate_Currency_BF function is 2 which in the function definition indicates no currency code found or some other error
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Currency code does not exist'||i.curr_code); --This line and the next is for debugging to help us understand where the code failed and why
                          dbms_output.put_line('currency');
                          l_error_flag :=1; --Since there was an error, change the error flag
                      end if;
                    end;   
                    
                    --Validate and get Vendor ID
                    l_vendor_id := PO_VALID_PKG_BF.get_VendorID_BF(i.vendor_number); -- Here is another function get_VendorID_BF defined later, we are inputting the vendor_number value of the current row [i] we are on from cur_po_order_header
                    
                    if nvl(l_vendor_id,0) = 0 then --nvl(a,b) function returns a if a is not null, and returns b if a is null, therefore the following if block will only execute when l_vendor_id is null meaning get_VendorID_BF failed to return anything
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Vendor Number does not exist'||i.vendor_number); -- more debugging code
                        l_error_flag :=1;
                        dbms_output.put_line('vendor');
                    end if;

                    --Validate and get Agent ID
                    l_agent_id := PO_VALID_PKG_BF.get_EmployeeId_BF(i.agent_number); -- This code block is structured similarly to above get_VendorID_BF validation 
                    dbms_output.put_line('agent Id'||l_agent_id);
                    if nvl(l_agent_id,0) = 0 then
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'Agent Number does not exist'||i.agent_number);
                            l_error_flag :=1;
                            dbms_output.put_line('Vendor Id');
                    end if;

                    dbms_output.put_line(l_error_flag);-- this line and the following is more debugging. It will fire even if there is no error.
                    fnd_file.put_line(fnd_file.log,'Error Flag is :-'||l_error_flag);

                    IF l_error_flag  = 0 THEN   -- this l_error_flag is mentioned a lot during the validation, if any one of them fails then this becomes something other than 0,and the following insertion code never executes
                        fnd_file.put_line(fnd_file.log,'Inserting Data'); -- if you see 'Inserting Data' in your log, than all validations must have cleared 
                        INSERT INTO po_headers_interface ( -- this is an SQL statement that inserts data into po_headers_interface table with below columns/values
                                                              interface_header_id
                                                            , batch_id
                                                            , action
                                                            , document_type_code
                                                            , currency_code
                                                            , agent_id
                                                            , vendor_id
                                                            , vendor_site_code
                                                            , approval_status
                                                            , ship_to_location
                                                            , bill_to_location
                                                            , org_id
                                                            , created_by
                                                            , creation_date
                                                            , last_update_login
                                                            , last_updated_by
                                                            , last_update_date
                                                            )
                                                    VALUES ( ln_po_header_id
                                                            , ln_batch_id
                                                            , 'ORIGINAL'
                                                            , 'STANDARD'
                                                            , i.curr_code
                                                            , l_agent_id
                                                            , l_vendor_id                                       
                                                            , PO_VALID_PKG_BF.get_vendor_siteId_BF(l_vendor_id) -- this function is defined at the bottom of the code, 
                                                          -- ,i.bill_to_location -- I may just delete this since it is already commented out...
                                                            , 'INCOMPLETE'
                                                            , i.ship_to_location
                                                            , i.Ship_to_location
                                                            , gn_org_id
                                                            , gn_user_id
                                                            , SYSDATE
                                                            , gn_user_id
                                                            , gn_user_id
                                                            , SYSDATE
                                                            );
                                                          
                    END IF;
        --====================================================================
              --  For loop for insertion of lines records in interface table
        -- ====================================================================
                    FOR j IN cur_po_order_lines ( -- this is now a nested loop, and the following variables are being assigned here
                                                                          p_vendor_number        => i.vendor_number
                                                                        , p_ship_to_location  => i.ship_to_location
                                                                        , p_bill_to_location  => i.bill_to_location
                                                                        )
                                LOOP --LOOP B 
                                  SELECT PO_LINES_INTERFACE_S.nextval
                                  INTO ln_po_line_id
                                  FROM DUAL;    
                                dbms_output.put_line(ln_po_line_id);-- this is for debugging

                                BEGIN                          
                                        l_inventory_item_id :=  PO_VALID_PKG_BF.get_inventory_itemId_BF(j.inventory_item ); -- this function is defined below, but will return an inventory id other than 99999 if it is succesful 
                                        if l_inventory_item_id= 999999 then
                                              FND_FILE.PUT_LINE('FND_FILE.LOG','Item Number does not exist'||j.inventory_item); -- for debugging purposes
                                            l_error_flag :=1;
                                        end if;
                                      

                                END;
                                dbms_output.put_line(l_inventory_item_id);
                                dbms_output.put_line (ln_po_header_id||','|| ln_po_line_id||','||l_inventory_item_id||','||j.unit_of_measure||','|| j.unit_price||','||j.quantity||','||j.line_number||','||gn_user_id
                                                                  );
                                counter := counter + 1;      
                                insert into po_lines_interface (
                                                                    interface_header_id
                                                                  , interface_line_id
                                                                  , line_type
                                                                  , item_id
                                                                  ,item
                                                                  , item_description
                                                                  , UOM_CODE
                                                                  , unit_price
                                                                  , quantity
                                                                  , need_by_date
                                                                  , line_num
                                                                  , organization_id
                                                                  , created_by
                                                                  , creation_date
                                                                  , last_update_login
                                                                  , last_updated_by
                                                                  , last_update_date
                                                                  )
                                                          VALUES (
                                                                    ln_po_header_id
                                                                  , ln_po_line_id
                                                                  , 'Goods'
                                                                  , l_inventory_item_id
                                                                  , j.inventory_item
                                                                  , PO_VALID_PKG_BF.get_inventory_itemDscr_BF(j.inventory_item)
                                                                  , j.unit_of_measure
                                                                  , j.unit_price
                                                                  , j.quantity
                                                                  , TRUNC(SYSDATE) + 1
                                                                  , counter
                                                                  , gn_org_id
                                                                  , gn_user_id
                                                                  , SYSDATE
                                                                  , gn_user_id
                                                                  , gn_user_id
                                                                  , SYSDATE
                                                                  );
                                                      
                                                                  
                                END LOOP; --END OF LOOP B
                end loop; --END OF LOOP A
   commit;    
   end main;
--  _____ _   _ ____     ___  _____   __  __    _    ___ _   _ 
-- | ____| \ | |  _ \   / _ \|  ___| |  \/  |  / \  |_ _| \ | |
-- |  _| |  \| | | | | | | | | |_    | |\/| | / _ \  | ||  \| |
-- | |___| |\  | |_| | | |_| |  _|   | |  | |/ ___ \ | || |\  |
-- |_____|_| \_|____/   \___/|_|     |_|  |_/_/   \_\___|_| \_|

procedure Validate_Currency_BF(p_curr_code fnd_currencies.CURRENCY_CODE%Type,P_ret_txt OUT Number )
  is
    cursor vld_curr(x_cur_code varchar2) is
    select currency_code 
    from   fnd_currencies  -- This table in EBSDB has all currency codes
    where  currency_code=x_cur_code;

    l_curr_code fnd_currencies.CURRENCY_CODE%Type;

    begin
          open vld_curr(p_curr_code);
          fetch vld_curr into l_curr_code;
          if vld_curr%notfound then
             P_ret_txt := 2;
          else
             p_ret_txt := 1;
          end if;
          Close vld_curr;
    exception when too_many_rows then
              P_ret_txt := 2;
              when others then
              P_ret_txt := 2;
    end Validate_Currency_BF;


function get_VendorID_BF(p_vendor_num ap_suppliers.segment1%type )
    return number is
    cursor cur_vendor_id is
    select vendor_id 
    from   ap_suppliers 
    where  segment1 = p_vendor_num;
    l_vendor_id ap_suppliers.vendor_id%type;
    begin
    for i in cur_vendor_id  loop
        l_vendor_id := i.vendor_id;
    end loop;
    return(l_vendor_id);
    end get_VendorID_BF;   


 function get_EmployeeId_BF(p_agent_number per_all_people_f.employee_number%type) 
    return number is
    l_employee_id     per_all_people_f.person_id%type;
    begin
    SELECT person_id  into l_employee_id
    from   per_all_people_f 
    where  employee_number =p_agent_number
    and trunc(sysdate) between trunc(effective_start_date) and trunc(effective_end_date)
    and business_group_id = (select  business_group_id 
                             from    hr_operating_units 
                             where   organization_id=FND_PROFILE.VALUE('ORG_ID')
                             );
    return( l_employee_id);
    exception when no_data_found then
              return(0);
              when too_many_rows then
              return(0);
              when others then
              return(0);
    end get_EmployeeId_BF;  


function get_inventory_itemId_BF(p_inv_item mtl_system_items.segment1%type )
                           return number
  is
  l_inv_item_id mtl_system_items.inventory_item_id%type;
  begin
  select inventory_item_id 
        into
        l_inv_item_id 
  from   mtl_system_items 
  where  segment1        = p_inv_item
  and    organization_id = FND_PROFILE.VALUE('ORG_ID');
  return(l_inv_item_id );
  exception when no_data_found then
            return(999999);
            when too_many_rows then
            return(999999);
            when others then
            return(99999);
end get_inventory_itemId_BF;


function get_vendor_siteId_BF(p_vendor_id ap_suppliers.vendor_id%type)  --p_vendor_id will be l_vendor_id when this function is called above
  return varchar2 is 
  cursor cur_vendor_site is
        select vendor_site_code --get the vendor_site_code from ap_supplier_sites_all
        FROM   ap_supplier_sites_all a,ap_suppliers b
        where  a.vendor_id=b.vendor_id 
        and    a.terms_id=b.terms_id
        and    a.vendor_id=p_vendor_id -- this is the input of this function [p_vendor_id]
        and    a.org_id=FND_PROFILE.VALUE('ORG_ID');
  l_vendor_site_code   ap_supplier_sites_all.vendor_site_code%type;
  begin
  open cur_vendor_site;
  fetch cur_vendor_site into l_vendor_site_code; -- assign the output of the SQL defined in cur_vendor_site to l_vendor_site_code
  if cur_vendor_site%notfound then
      l_vendor_site_code := 'X'; -- just in case the SQL didnt return anything, we just asssign l_vendor_site_code to be X
  end if;
  close cur_vendor_site;
  return(l_vendor_site_code);
end get_vendor_siteId_BF ;


function get_inventory_itemDscr_BF(p_inv_item mtl_system_items.segment1%type )
                           return varchar2
  is
  l_inv_item_dscr mtl_system_items.description%type;
  begin
  select description
        into
        l_inv_item_dscr
  from   mtl_system_items
  where  segment1        = p_inv_item
  and    organization_id = FND_PROFILE.VALUE('ORG_ID');
  return(l_inv_item_dscr );
  exception when no_data_found then
            return('X');
            when too_many_rows then
            return('X');
            when others then
            return('X');
  end get_inventory_itemDscr_BF;

end PO_VALID_PKG_BF;