<?php
echo password_hash(strtolower(md5($argv[1])), PASSWORD_DEFAULT);
?>
