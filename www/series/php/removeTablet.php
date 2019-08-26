<?php

include '../seriesManagement.php';

$tabletManager = new tabletManagement();
$tabletManager->dbinit("../series.db");
$tabletManager->removeTablet($_POST['tabletId']);
$tabletManager->dbclose();

?>