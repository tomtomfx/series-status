<?php

include '../seriesManagement.php';

$seriesManager = new seriesManagement();
$seriesManager->configInit("../../secure/configWeb");
$seriesManager->dbinit("../series.db");

$searchShow = $_POST['serieName'];
$showsFound = getShowList ($searchShow, $seriesManager);
$content = formComboToAdd("Show:", $showsFound);

$seriesManager->dbclose();

echo json_encode($content);

?>