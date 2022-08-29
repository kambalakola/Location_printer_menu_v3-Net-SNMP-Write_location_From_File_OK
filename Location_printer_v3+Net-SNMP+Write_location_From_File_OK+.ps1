#Задача № 1 нобходимо, чтобы Location в свойствах принтера совпадал с описанием группы безопасности этого принтера
#Задача № 2 необходимо на принтере изменить Location на такой же как в группе безопасности, ограничение на запись в oid .1.3.6.1.2.1.1.6.0 - 32 английских символа
#####Скрипт получает на вход локальное имя принтера в переменную $item, 
#Преобразует $item в $item2 на основе Имени пирнтера, переменная $item3 - это Имя группы доступа, оно получаетяся сложением $item2 и преобразованием $item
#
#
#
#
Remove-Variable * -ErrorAction SilentlyContinue; Remove-Module *; $error.Clear(); Clear-Host

cls



function Printer_Set-SnmpData ($LocationPlusPortname) {



$Eng_GetLocationFromAD=$LocationPlusPortname[0]
$Printer_Port_Name=$LocationPlusPortname[1]

## Считываем данные о принтере(Устройстве) SNMP перед изменением 


$a = "snmpget -v 1 -c public " + $Printer_Port_Name  + "	 sysLocation.0"
$Printer_location_FromSNMP= iex $a |ft -HideTableHeaders| Out-String
$Printer_location_FromSNMP = $Printer_location_FromSNMP.trimstart('MPv2-MIB::sysLocation.0 = STRING: ')
Write-Host "SNMP_Location до изменения   :"$Printer_location_FromSNMP
Write-Host

############-----сокращаем до 32 английских символа--------############
$32ch_Eng_GetLocationFromAD =  foreach ($str in $Eng_GetLocationFromAD) { $str -replace '(.{32}).+','$1' }

############-----убираем перенос строки--------############
$32ch_Eng_GetLocationFromAD = $32ch_Eng_GetLocationFromAD.Trim()
############-----Получаем Имя Порта--------############
#$Printer_Port_Name = Get-Printer -ComputerName $Print_Server -Name $item | Select PortName |ft -HideTableHeaders | Out-String 
############-----убираем перенос строки--------############
#$Printer_Port_Name = $Printer_Port_Name.Trim()

#Write-Host "FUNC Printer_Port_Name        :" $Printer_Port_Name
#Write-Host "32ch_Eng_GetLocationFromAD    :" $32ch_Eng_GetLocationFromAD

$a = "snmpset -v 1 -c public " + $Printer_Port_Name + "	sysLocation.0 s ""$32ch_Eng_GetLocationFromAD"" "
############-----Прописываем по SNMP новый Location--------############
###Командлет Invoke-Expression или iex обрабатывает или выполняет заданную строку в качестве команды и возвращает результаты выражения или команды.
iex $a

## Считываем данные о принтере(Устройстве) SNMP 

$a = "snmpget -v 1 -c public " + $Printer_Port_Name  + " sysLocation.0"
$Printer_location_FromSNMP= iex $a |ft -HideTableHeaders| Out-String
$Printer_location_FromSNMP = $Printer_location_FromSNMP.trimstart('MPv2-MIB::sysLocation.0 = STRING: ')
$Printer_location_FromSNMP = $Printer_location_FromSNMP.trim()
Write-Host "SNMP_Location Изменен на     :"$Printer_location_FromSNMP
Write-Host

}



function GetTrans #++++++++++++++++ Функция транслитерации +++++++++++++++++++
 {
    param ($StrIn)
    $ArrIn = $StrIn -split ""
    $ArrOut = $ArrIn
    $RuAlph = "А","Б","В","Г","Д","Е","Ё","Ж","З","И","Й","К","Л","М","Н","О","П","Р","С","Т","У","Ф","Х","Ц","Ч","Ш","Щ","Ъ","Ы","Ь","Э","Ю","Я"
    $TrAlph = "a","b","v","g","d","e","yo","zh","z","i","j","k","l","m","n","o","p","r","s","t","u","f","kh","ts","ch","sh","shh","","y","","e","yu","ya"

    for ($i=0; $i -lt $ArrIn.Length; $i++) {
        for ($j=0; $j -lt 33; $j++) {    
            if ($ArrIn[$i] -eq $RuAlph[$j])  {
                $ArrOut[$i] = $TrAlph[$j]
            }	
        }
        $StrOut = $StrOut + $ArrOut[$i]
        }
    $StrOut
}




#+++++++++++++++++++++++++++++++++++
####################Установка компонентов
#Install-Module -Name SNMP
#set-executionpolicy remotesigned
#import-module snmp
#get-help snmp
Import-Module ActiveDirectory;
$Print_Server='VLD-PS03'
#$CSV_File_To_Import файл со списском на сканирование
$CSV_File_To_Import = 'D:\work\_task\202107\05\Import_Printer_Location_240921.csv'
#$CSV_File_To_Export - файл с результатамаи опроса сервера , групп и устройств
$CSV_File_To_Export = 'D:\work\_task\202107\05\Exported_Printer_Location_test1.csv'

$CSV_File_To_Record = 'C:\Share\Scripts\print_server&roups\Record_Printer_Location_DZO_01122021.csv'

#+++++++++++++++++++++ ТЕЛО +++++++++++++++++++
#++++++++++-------на вход подаем имя принтера++++++++

function Check_printer_for_group  ($item){


$item2 = switch ( $item )
{
    {$item -match "VLDVPB-"} {
        "gf-vld-vpb_printer_P"
        $item3 =$item2 + $item.trimstart('VLDVPB-')}

    {$item -match "VLDVP-"} {
        "gf-vld-vmtp_printer_P" 
        $item3 =$item2 + $item.trimstart('VLDVP-')}

    {$item -match "VLDVAT-"} {
        'gf-vld-vat_printer_'
         $item3 =$item2 + $item.trimstart('VLDVAT-')}

    {$item -match "VLDPK-"} {
        'gr-vld-portcontract_printer_P'
        $item3 =$item2 + $item.trimstart('VLDPK-')}

    {$item -match "VLDPF-"} {
        'gf-vld-portoflot_printer_P'
        $item3 =$item2 + $item.trimstart('VLDPF-')}

    {$item -match "VLDPDV-"} {
        'gf-vld-vmtp_printer_P'
         $item3 =$item2 + $item.trimstart('VLDPDV-')}

    {$item -match "VLDFM-"} {
        'gf-vld-femsta_printer_'
         $item3 =$item2 + $item.trimstart('VLDFM-')}     

}

$ResultGroup=$item2 + $item3
#Write-Host "Найдено имя Группы доступа: " $ResultGroup


Try { ## Проверяем существут ли группа в домене
        $GroupForCheck = $ResultGroup 
        

 
		$GetLocationFromAD= Get-ADGroup -Properties * -identity $GroupForCheck | Select Description |ft -HideTableHeaders | Out-String
         #Write-Host "GroupForCheck: " $GroupForCheck 
        }
	Catch 
            {$GetLocationFromAD  = ""
           $ResultGroup  = "Группа не Найдена в домене"
            } 


#$GetLocationFromAD = Get-ADGroup -Properties * -identity $ResultGroup | Select Description |ft -HideTableHeaders | Out-String

$GetLocationFromAD= $GetLocationFromAD.Trim()
$Group_LocationFromAD=$GetLocationFromAD

$array = $ResultGroup,$GetLocationFromAD

return $array
}

function Printer_input ($item) {

#$Printer_Name=Get-Printer -ComputerName $Print_Server -Name "VLDVP-P301" | Select Name, Location  #|ft -HideTableHeaders
$Printer_About = Get-Printer -ComputerName $Print_Server -Name $item  | Select Name, Location, portname

$Printer_Name = Get-Printer -ComputerName $Print_Server -Name $item  | Select Name |ft -HideTableHeaders| Out-String 
$Printer_Name=$Printer_Name.Trim()
#$Printer_Name

$Printer_Location = Get-Printer -ComputerName $Print_Server -Name $item  | Select Location |ft -HideTableHeaders| Out-String 
$Printer_Location=$Printer_Location.Trim()
#$Printer_Location

$Printer_portname = Get-Printer -ComputerName $Print_Server -Name $item  | Select portname |ft -HideTableHeaders| Out-String 
$Printer_portname=$Printer_portname.Trim()
#$Printer_portname



if ($Printer_Name) {#Write-Host "Принтер: "  $Printer_Name  }
} 
else { Write-Host "Принтер не найден. Выход "
exit

}
$array = $Printer_Name,$Printer_Location,$Printer_portname

return $array 

}

function get_status($path_ip) {
	if ((Test-Connection -Count 1 -computer $path_ip -quiet) -eq $True)
		{$statis_IP= "ONline"}
	Else {{$statis_IP= "OFFLine"}} 
	return $statis_IP
}
#### BODY
while ($True){
$param = Read-Host "Введите парамтр: 1 - ручной ввод, 2 - Сканировать из файла , 3 - Записать из файла"
switch ($param) 
{
        stop    { exit }
        default { break }
        1 # 1 - ручной ввод 
        {
         



$param = Read-Host "Ведите Имя принтера, stop для отмены"

    switch ($param) {
        stop    { exit }
        default { $PrinterName = $param }
        }
$item =$param.Trim()

## Считываем данные о принтере
$Printer_input_array = Printer_input -item $item
## Считываем данные о ГруппеДоступа
$Check_printer_for_group_array = Check_printer_for_group -item $item

## Считываем данные о Расположении по SNMP
$a = "snmpget -v 1 -c public " + $Printer_input_array[2]  + "	 sysLocation.0"
$Printer_location_FromSNMP= iex $a |ft -HideTableHeaders| Out-String
$Printer_location_FromSNMP = $Printer_location_FromSNMP.trimstart('MPv2-MIB::sysLocation.0 = STRING: ')


$Real_Printer_Status = get_status $Printer_input_array[2]

Write-Host "$item           :"$item
Write-Host 
Write-Host "----DATA---------------------------------------------------------------------------"
Write-Host "(Print_Server)            :"$Print_Server 
Write-Host
Write-Host "1.-Server-------------------------"
Write-Host "Имя Принтера            :"$Printer_input_array[0]
Write-Host "Расположение принтера   :"$Printer_input_array[1]
Write-Host "Порт принтера           :"$Printer_input_array[2]
Write-Host
Write-Host "2.-AD_Groups-----------------------"
Write-Host "Группа доступа          :" $Check_printer_for_group_array[0]
Write-Host "Описание Группы доступа :"$Check_printer_for_group_array[1]
Write-Host
Write-Host "3-(SNMP)------------------------"
Write-Host "Статус IP принтера      :"$Real_Printer_Status
Write-Host "Описание Принтра SNMP   :"$Printer_location_FromSNMP
Write-Host 
Write-Host '---HOW_TO_EDIT_?---------------------------------------------------------------------'
Write-Host '.(Print_Server)  Принтер '
Write-Host '11 Printer Location вручную'
Write-Host '12 Из группы доступа (AD)'
Write-Host
Write-Host '.(AD_Groups) Location для группы доступа'
Write-Host '21 Из Принтера (Принт-сервер)'
Write-Host '22 Group Location вручную'
Write-Host
Write-Host '.(SNMP) Location по IP на Устройство'
Write-Host '31 Из Принтера (Принт-сервер)'
Write-Host '32 Из группы доступа (AD)'
Write-Host '33 SNMP Location вручную'
Write-Host '--------------------------------------------------------------------------------------'
}
        2 #2 - Сканировать из файла
        {   
        
         # Import the data from CSV file and assign it to variable

$param = Read-Host "Файл Импорта Списска принтеров. Ведите путь и ммя файла  "

    switch ($param) {
        stop    { exit }
        default { $CSV_File_To_Import = $param }
        }

$param = Read-Host "Файл Экспорта Списска принтеров. Ведите путь и ммя файла  "

    switch ($param) {
        stop    { exit }
        default { $CSV_File_To_Export = $param }
        }
       


        $CSV_Data_To_Import = Import-Csv $CSV_File_To_Import
        Clear-Content $CSV_File_To_Export
        Add-Content $CSV_File_To_Export "printer_name,printer_port,printer_location,group_name,group_location,ip_spatus,snmp_location" -Encoding utf8  -notypeinformation
        
######################
foreach ($Item_From_CSV in $CSV_Data_To_Import) {

    $PrinterFromCSV = $Item_From_CSV.printer_name
    ## Считываем данные о принтере
    $Printer_input_array = Printer_input -item $PrinterFromCSV
    ## Считываем данные о ГруппеДоступа
    $Check_printer_for_group_array = Check_printer_for_group -item $PrinterFromCSV

    ## Считываем данные о принтере(Устройстве) SNMP 

    ###########################

        $a = "snmpget -v 1 -c public " + $Printer_input_array[2]  + "	 sysLocation.0"
        $Printer_location_FromSNMP= iex $a |ft -HideTableHeaders| Out-String
        $Printer_location_FromSNMP = $Printer_location_FromSNMP.trimstart('MPv2-MIB::sysLocation.0 = STRING: ')
        $Printer_location_FromSNMP = $Printer_location_FromSNMP.trim()
    ##############################

    $Real_Printer_Status = get_status $Printer_input_array[2]

    #$array_Line_to_Export = ИМЯ_Принтера, Порт,Расположение принтера,Группа доступа,Описание Группы доступа,Статус IP принтера , Описание Принтра SNMP 
    #$array_Line_to_Export = $PrinterFromCSV,$Printer_input_array[2],$Printer_input_array[1],$Check_printer_for_group_array[0],$Check_printer_for_group_array[1],$Real_Printer_Status,$Printer_location_FromSNMP
    #$array_Line_to_Export
    #$array_Line_to_Export| Export-Csv  -Encoding utf8 $CSV_File_To_Export -Append 

############Записываем данные в экспорт начало

#[PSCustomObject]
           # @{
           # printer_name =  $PrinterFromCSV
           # printer_port = $Printer_input_array[2]
           # printer_location = $Printer_input_array[1]
           # group_name = $Check_printer_for_group_array[0]
           # group_location = $Check_printer_for_group_array[1]
           # ip_spatus = $Real_Printer_Status
           # snmp_location = $Printer_location_FromSNMP
           #}#| export-csv -path $CSV_File_To_Export -Delimiter "," -Encoding utf8 -Append -NoTypeInformation
          $PrinterFromCSV
          $Printer_input_array[2]
          $Printer_input_array[1]
          $Check_printer_for_group_array[0]
          $Check_printer_for_group_array[1]
          $Real_Printer_Status
          $Printer_location_FromSNMP



            $Output =New-Object -TypeName PSObject -Property @{
            'printer_name' =  $PrinterFromCSV
            'printer_port' = $Printer_input_array[2]
            'printer_location' = $Printer_input_array[1]
            'group_name' = $Check_printer_for_group_array[0]
            'group_location' = $Check_printer_for_group_array[1]
            'ip_spatus' = $Real_Printer_Status
            'snmp_location' = $Printer_location_FromSNMP
    } | Select-Object printer_name,printer_port,printer_location,group_name,group_location,ip_spatus,snmp_location #| Export-Csv $CSV_File_To_Export -Encoding utf8 -Append -NoTypeInformation -Delimiter ","
   

   $Output | Export-Csv $CSV_File_To_Export -Encoding utf8 -Append -NoTypeInformation -Delimiter ","
    


}

          }
        3 { # Запись из Файла
         Write-Host "Куда Записать Расположение:"
         Write-Host "Принт-сервер           -                                          1"
         Write-Host "Группу доступа         -                                          2"
         Write-Host "SNMP из Принтера       -                                         31"
         Write-Host "SNMP из Группы Доступа -                                         32"
         Write-Host "записать ВСЕ новое из файла в : группу, Принтер, Устройство      40"
        $param = Read-Host "Введите параметр Для записи расположения из файла"
            switch ($param) 
                {

                stop    { exit }
                default { break }
                1 # Записать Расположение в Принт-сервер   
                {
                $CSV_Data_To_Record = Import-Csv $CSV_File_To_Record # –Delimiter “,”
                foreach ($Item_From_CSV in $CSV_Data_To_Record)
                     {
                        $PrinterFromCSV = $Item_From_CSV.printer_name
                        $PrinterFromCSV
                        $locationFromCSV = $Item_From_CSV.printer_location
                        Set-Printer -ComputerName $Print_Server -Name $PrinterFromCSV -Comment $locationFromCSV -Location $locationFromCSV
               
                    }
                 break 
                }
                2 # Записать Расположение в Группу доступа
                { 
                $CSV_Data_To_Record = Import-Csv $CSV_File_To_Record # –Delimiter “,”
                foreach ($Item_From_CSV in $CSV_Data_To_Record)
                     {
                    $PrinterFromCSV = $Item_From_CSV.printer_name
                    $locationFromCSV = $Item_From_CSV.group_location
                    $groupFromCSV = $Item_From_CSV.group_name
                    Set-ADGroup -identity $groupFromCSV -description $locationFromCSV

                    $Check_printer_for_group_array = Check_printer_for_group -item $PrinterFromCSV
                    Write-Host $PrinterFromCSV "             -          " $Check_printer_for_group_array[1]
                    }
                 break  }
                31 # записать SNMP из Принтера     
                 {   
                $CSV_Data_To_Record = Import-Csv $CSV_File_To_Record # –Delimiter “,”
                foreach ($Item_From_CSV in $CSV_Data_To_Record)
                     {
                    $PrinterFromCSV = $Item_From_CSV.printer_name
                    $locationFromCSV = $Item_From_CSV.printer_location
                    $PortFromCSV = $Item_From_CSV.printer_port

                               ############----- Отрезаем от Расположения модель Принтера по последней запятой--------############
                        $SRC_GetLocation = $locationFromCSV
                        $SRC_GetLocation = $SRC_GetLocation.Substring(0,$SRC_GetLocation.lastIndexOf(','))
                        $SRC_GetLocation = $SRC_GetLocation.Trim()
                        $PortFromCSV = $Item_From_CSV.printer_port
                        
                            ############-----Преобразовывам Расположение в Английский--------############
                        $Eng_GetLocationFromAD = GetTrans $SRC_GetLocation
                        $LocationPlusPortname = $Eng_GetLocationFromAD,$PortFromCSV
                        
                        Write-Host $PrinterFromCSV $PortFromCSV
                        $Modified_SNMP_LOcation = Printer_Set-SnmpData $LocationPlusPortname

                                            
                    }
                 
                 
                 break 
                 
                 }
                32 { 
                Write-Host " не используется запись SNMP из Группы Доступа " 
                break }
                40 # записать ВСЕ новое из файла в : группу, Принтер, Устройство


                {   
                $CSV_Data_To_Record = Import-Csv $CSV_File_To_Record # –Delimiter “,”
                foreach ($Item_From_CSV in $CSV_Data_To_Record)
                     {

                        # Записать Расположение в Принт-сервер
                        "'n+++запись Расположение в Принт-сервер "
                        $PrinterFromCSV = $Item_From_CSV.printer_name
                        $PrinterFromCSV
                        $locationFromCSV = $Item_From_CSV.printer_location
                        Set-Printer -ComputerName $Print_Server -Name $PrinterFromCSV -Comment $locationFromCSV -Location $locationFromCSV
                        
                        # Записать Расположение в Группу доступа
                        "'n+++запись Расположение в Группу доступа " 
                    $PrinterFromCSV = $Item_From_CSV.printer_name
                    $locationFromCSV = $Item_From_CSV.group_location
                    $groupFromCSV = $Item_From_CSV.group_name
                    Set-ADGroup -identity $groupFromCSV -description $locationFromCSV
                    $Check_printer_for_group_array = Check_printer_for_group -item $PrinterFromCSV
                    Write-Host $PrinterFromCSV "             -          " $Check_printer_for_group_array[1]


                    # записать SNMP из Принтера
                    "'n+++запись SNMP из Принтера " 
                    $PrinterFromCSV = $Item_From_CSV.printer_name
                    $locationFromCSV = $Item_From_CSV.printer_location
                    $PortFromCSV = $Item_From_CSV.printer_port

                               ############----- Отрезаем от Расположения модель Принтера по последней запятой--------############
                        $SRC_GetLocation = $locationFromCSV
                        $SRC_GetLocation = $SRC_GetLocation.Substring(0,$SRC_GetLocation.lastIndexOf(','))
                        $SRC_GetLocation = $SRC_GetLocation.Trim()
                        $PortFromCSV = $Item_From_CSV.printer_port
                        
                            ############-----Преобразовывам Расположение в Английский--------############
                        $Eng_GetLocationFromAD = GetTrans $SRC_GetLocation
                        $LocationPlusPortname = $Eng_GetLocationFromAD,$PortFromCSV
                        
                        Write-Host $PrinterFromCSV $PortFromCSV
                        $Modified_SNMP_LOcation = Printer_Set-SnmpData $LocationPlusPortname

                                            
                    }
                 
                 
                 break 
                 
                 }
                }
          }
 }

############-----Записываем данные в  Сервер \ Группу доступа \ принтер ----#################
$param = Read-Host "Введите парамтр "
switch ($param) 
{
        stop    { exit }
        default { break }
        11 #11 Printer Location вручную
         { 
         
        $param = Read-Host "Введите описание принтера в виде <Кабинет,Здание,МодельПринтера> , stop для отмены"
                switch ($param)
                        {
                default {$Printer_Manual_Location =$param.Trim()
                         Write-Host "Описание Принтра  :"$Printer_Manual_Location
                         Set-Printer -ComputerName $Print_Server -Name $Printer_input_array[0] -Comment $Printer_Manual_Location -Location $Printer_Manual_Location
                            $Printer_input_array = Printer_input -item $item
                            Write-Host "1.-Server-(Обновлено)-------------------------"
                            Write-Host "Новое Расположение принтера   :"$Printer_input_array[1]
                        }
                        }
             } 
        12 #12 Printer Location Из группы доступа (AD)
         { Set-Printer -ComputerName $Print_Server -Name $Printer_input_array[0] -Comment $Check_printer_for_group_array[1] -Location $Check_printer_for_group_array[1]
        
         
              $GetLocationFromAD = Get-ADGroup -Properties * -identity $Check_printer_for_group_array[0] | Select Description |ft -HideTableHeaders | Out-String
              $GetLocationFromAD=$GetLocationFromAD.Trim()
              $Printer_input_array = Printer_input -item $item
                Write-Host "1.-Server-(Обновлено)-------------------------"
                Write-Host "Новое Расположение принтера   :"$Printer_input_array[1]

             } 
        21 # Прописать Location для группы доступа (AD) Из Принтера (Принт-сервер)
         {
                Set-ADGroup -identity $Check_printer_for_group_array[0] -description $Printer_input_array[1]
                $GetLocationFromAD = Get-ADGroup -Properties * -identity $Check_printer_for_group_array[0] | Select Description |ft -HideTableHeaders | Out-String
                $GetLocationFromAD=$GetLocationFromAD.Trim()
                Write-Host "2.-AD_Groups-(Обновлено)-----------------------"
                Write-Host "Новое описание Группы доступа :"$GetLocationFromAD
          }
        22 # (AD_Groups) Location для группы доступа  Group Location вручную
         {
                $param = Read-Host "Введите описание Группы в виде <Кабинет,Здание,МодельПринтера> , stop для отмены"
                switch ($param)
                        {
                default {$Group_Manual_Location =$param.Trim()
                            Write-Host "Описание Группы  :"$Group_Manual_Location
                            Set-ADGroup -identity $Check_printer_for_group_array[0] -description $Group_Manual_Location
                            $GetLocationFromAD = Get-ADGroup -Properties * -identity $Check_printer_for_group_array[0] | Select Description |ft -HideTableHeaders | Out-String
                            $GetLocationFromAD=$GetLocationFromAD.Trim()
                            Write-Host "2.-AD_Groups-(Обновлено)-----------------------"
                            Write-Host "Новое описание Группы доступа :"$GetLocationFromAD
                        }
                        }
          }
        31 #(SNMP) Location по IP на Устройство' Из Принтера (Принт-сервер)'
         {
                                   ############----- Отрезаем от Расположения модель Принтера по последней запятой--------############
                        $SRC_GetLocation = $Printer_input_array[1]
                        $SRC_GetLocation = $SRC_GetLocation.Substring(0,$SRC_GetLocation.lastIndexOf(','))
                        $SRC_GetLocation = $SRC_GetLocation.Trim()
                        
                        
                            ############-----Преобразовывам Расположение в Английский--------############
                        $Eng_GetLocationFromAD = GetTrans $SRC_GetLocation
                        $Printer_Port_Name=$Printer_input_array[2]
                        $LocationPlusPortname = $Eng_GetLocationFromAD,$Printer_Port_Name
                        $Eng_GetLocationFromAD
                        $Printer_Port_Name
                        $Modified_SNMP_LOcation = Printer_Set-SnmpData $LocationPlusPortname
                        #Write-Host
                        #Write-Host "LocationPlusPortname    :"$LocationPlusPortname
                        #Write-Host "SNMP_Location Изменен на:"
                        #$Real_Printer_Status = get_status $Printer_input_array[2]
                        #Write-Host "Статус IP принтера      :"$Real_Printer_Status
                        #Write-Host "Описание Принтра SNMP   :"$Modified_SNMP_LOcation
                        #Write-Host
                       
                        break
          }
        32 #(SNMP) Location по IP на Устройство' Из группы доступа (AD)'
         {
          ############----- Отрезаем от Расположения модель Принтера по последней запятой--------############
                        $SRC_GetLocation = $Check_printer_for_group_array[1]
                        $SRC_GetLocation = $SRC_GetLocation.Substring(0,$SRC_GetLocation.lastIndexOf(','))
                        $SRC_GetLocation = $SRC_GetLocation.Trim()
                        
                        
                            ############-----Преобразовывам Расположение в Английский--------############
                        $Eng_GetLocationFromAD = GetTrans $SRC_GetLocation
                        $Printer_Port_Name=$Printer_input_array[2]
                        $LocationPlusPortname = $Eng_GetLocationFromAD,$Printer_Port_Name
                        $Modified_SNMP_LOcation = Printer_Set-SnmpData $LocationPlusPortname
                        #Write-Host
                        #Write-Host "LocationPlusPortname    :"$LocationPlusPortname
                        #Write-Host "SNMP_Location Изменен на:"
                        #$Real_Printer_Status = get_status $Printer_input_array[2]
                        #Write-Host "Статус IP принтера      :"$Real_Printer_Status
                        #Write-Host "Описание Принтра SNMP   :"$Modified_SNMP_LOcation
                        #Write-Host
                       
                        break

          }
        33 # (SNMP) Location по IP на Устройство'SNMP Location вручную'
         {
           $param = Read-Host "Введите Расположение принтера в виде <Кабинет,Здание> , stop для отмены"
                switch ($param)
                        {
                default {$GetLocation =$param.Trim()
                        $SRC_GetLocation = $GetLocation
                        $SRC_GetLocation = $SRC_GetLocation.Trim()
                        
                        
                            ############-----Преобразовывам Расположение в Английский--------############
                        $Eng_GetLocationFromAD = GetTrans $SRC_GetLocation
                        $Printer_Port_Name=$Printer_input_array[2]
                        $LocationPlusPortname = $Eng_GetLocationFromAD,$Printer_Port_Name
                        $Modified_SNMP_LOcation = Printer_Set-SnmpData $LocationPlusPortname
                        
                       
                        break
                         
                        }
                        }   
          }
        }
        
#Write-Host "test EXIT :"

}
