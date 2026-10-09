function AddStartingBasesSummary($summaryPath,$report){
    $text=[IO.File]::ReadAllText($summaryPath)
    $lines=[Collections.Generic.List[string]]::new()
    $lines.Add('## [Стартовые позиции главных баз](StartingBases/Summary.md)');$lines.Add('')
    $lines.Add('Кандидаты HQ, выбираемые при запуске миссии. Вместимость относится к создаваемому командному пункту, а не ко всей ресурсной сети базы. Данные кандидатов не прибавляются к общему начальному запасу.');$lines.Add('')
    $lines.Add('| Позиция | Вместимость КП, припасы | Базовое пополнение за цикл, припасы | Пополнение, мин. |');$lines.Add('| --- | ---: | ---: | ---: |')
    foreach($record in $report.records){$lines.Add("| [$($record.name)](StartingBases/$($record.name).md) | $($record.commandPostCapacitySupplies) | $($record.incomePerCycle.ToString('0.###',[Globalization.CultureInfo]::InvariantCulture)) | $($record.arrivalIntervalMinutes.ToString('0.###',[Globalization.CultureInfo]::InvariantCulture)) |")};$lines.Add('');$lines.Add('')
    $pattern='(?ms)^## \[Стартовые позиции главных баз\][^\r\n]*\r?\n.*?(?=^## |\z)'
    $text=[regex]::Replace($text,$pattern,'')
    $anchor='## [Контрольные точки](ControlPoints/Summary.md)'
    if(!$text.Contains($anchor)){throw 'Missing control point section for starting-base category.'}
    $text=$text.Replace($anchor,($lines -join "`n")+$anchor)
    [IO.File]::WriteAllText($summaryPath,$text,[Text.UTF8Encoding]::new($false))
}
