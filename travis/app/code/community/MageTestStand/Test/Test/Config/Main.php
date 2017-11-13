<?php

class MageTestStand_Test_Test_Config_Main extends EcomDev_PHPUnit_Test_Case_Config
{
    public function testModuleActive()
    {
        $this->assertModuleIsActive();
    }

    public function testModuleVersion()
    {
        $this->assertModuleVersion('1.0.0');
    }
}