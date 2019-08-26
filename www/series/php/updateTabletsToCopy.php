<?php

include '../seriesManagement.php';

$tabletManager = new tabletManagement();
$tabletManager->dbinit("../series.db");

$content = formComboToCopy("Tablet:", $tabletManager, "copyToTablet");

$tabletManager->dbclose();

echo json_encode($content);

?>