<?php

include '../seriesManagement.php';

$seriesManager = new seriesManagement();
$seriesManager->configInit("../../secure/configWeb");
$seriesManager->dbinit("../series.db");

$showsList = getCurrentShowList ($seriesManager);
$content = formComboToArchive("Show:", $showsList);

$seriesManager->dbclose();

echo json_encode($content);

?>