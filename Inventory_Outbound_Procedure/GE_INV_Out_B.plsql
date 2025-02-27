-- Following code was taken from here https://www.askhareesh.com/2015/07/plsql-script-of-purchase-order-interface.html
-- I have formatted it to be more easy to read and have added comments to demonstrate my understanding of it and to help others better understand it
-- I have modified some parts of the original code which are documented in the comments as well

CREATE OR REPLACE procedure GE_INV_Out_BAL(
    Errbuf OUT varchar2, -- Errbuf and Retcode are standard OUT variables for communicating wether there was an issue with the execution of the code, 0 = good, 1=warning,2=Fail, and also to capture any error message
    Retcode ouT varchar2,
    f_id    in number, --f_id and t_id are supposed to be organization ids. They represent the range of which we will grab inventory data from. For this demo purpose both of these values will be 204 which will only grab from Vision Operations Organization from the demo instance of Oracle EBS
    t_id    in varchar2)
AS
    x_id     utl_file.file_type; -- this is the variable to represent the output file we will write to
    l_count  number(5) default 0; -- will be used for counting the amount of lines written to the outfile
    cursor c1 is select --c1 is the cursor that will hold the values of the columns from the different inventory tables we will query
        msi.segment1 item,
        msi.inventory_item_id Itemid,
        msi.description  itemdesc,
        msi.primary_uom_code Uom,
        ood.organization_name name,
        ood.organization_id   id,
        mc.segment1||','||mc.segment2 Category
        from
        mtl_system_items_b           msi, --Stores core item master data in Oracle Inventory- Represents fundamental item attributes and configurations
        org_organization_definitions ood, --view to get organization name from HR_ORGANIZATION_UNITS
        mtl_item_categories          mic, -- Stores item category assignments for inventory items
        mtl_categories               mc --stores inventory item assignments to categories within a category set
        where -- these joins link the tables we are querying based on organization_id
        msi.organization_id       = ood.organization_id
        and msi.inventory_item_id = mic.inventory_item_id
        and msi.organization_id   = mic.organization_id
        and mic.category_id       = mc.category_id
        and msi.purchasing_item_flag = 'Y'
        and msi.organization_id between f_id and t_id;
BEGIN
    x_id:=utl_file.fopen('/tmp','invoutdata.txt','W'); -- changed output file path location to /tmp for linux machine application server - CODE CHANGE FROM ORIGINAL 
    -- above line opens the file variable in order for us to write to
    for x1 in c1 loop -- x1 represents the current row from the query results of the cursor c1 defined above. Using a loop we will go through each row
    l_count:=l_count+1; -- increment the line count variable
    -- the following put_line writes to the output file. Each line puts the following values seperated by '-'
    utl_file.put_line(  x_id,
                        x1.item    ||'-'||
                        x1.itemid  ||'-'||
                        x1.itemdesc||'-'||
                        x1.uom   ||'-'||
                        x1.name   ||'-'||
                        x1.id   ||'-'||
                        x1.category   );
    end loop;
    utl_file.fclose(x_id); --close file to end writing
    --following lines of code is for logging and will be found in the outfile /u01/install/APPS/fs_ne/inst/ebsdb_apps/logs/appl/conc/out/o[REQUEST_ID].txt   replace REQUEST_ID here with yours 
    Fnd_file.Put_line(Fnd_file.output,'No of Records transfered to the data file :'||l_count);
    Fnd_File.Put_line(fnd_File.Output,' ');
    Fnd_File.Put_line(fnd_File.Output,'Submitted User name  '||Fnd_Profile.Value('USERNAME'));
    Fnd_File.Put_line(fnd_File.Output,' ');
    Fnd_File.Put_line(fnd_File.Output,'Submitted Responsibility name '||Fnd_profile.value('RESP_NAME'));
    Fnd_File.Put_line(fnd_File.Output,' ');
    Fnd_File.Put_line(fnd_File.Output,'Submission Date :'|| SYSDATE);
EXCEPTION
    -- The following exceptions are for if there is anything wrong when dealing with the output file 
    WHEN utl_file.invalid_operation THEN
    fnd_file.put_line(fnd_File.log,'invalid operation');
    utl_file.fclose_all;
    WHEN utl_file.invalid_path THEN
    fnd_file.put_line(fnd_File.log,'invalid path'); -- this particular line helped me realize I should change code to account for linux instead of windows in output file path location (line 34)
    utl_file.fclose_all;
    WHEN utl_file.invalid_mode THEN
    fnd_file.put_line(fnd_File.log,'invalid mode');
    utl_file.fclose_all;
    WHEN utl_file.invalid_filehandle THEN
    fnd_file.put_line(fnd_File.log,'invalid filehandle');
    utl_file.fclose_all;
    WHEN utl_file.read_error THEN
    fnd_file.put_line(fnd_File.log,'read error');
    utl_file.fclose_all;
    WHEN utl_file.internal_error THEN
    fnd_file.put_line(fnd_File.log,'internal error');
    utl_file.fclose_all;
    WHEN OTHERS THEN
    fnd_file.put_line(fnd_File.log,'other error');
    utl_file.fclose_all;
End GE_INV_Out_BAL;