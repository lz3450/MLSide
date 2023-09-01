#include <linux/init.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/timer.h>
#include <asm/msr.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("KZL");
MODULE_DESCRIPTION("A module to print TSC every second");
MODULE_VERSION("0.1");

static struct timer_list my_timer;

static void print_tsc(struct timer_list *t)
{
    unsigned long long tsc;
    rdmsrl(MSR_IA32_TSC, tsc);
    printk(KERN_INFO "Current TSC: %llu\n", tsc);

    /* Reset the timer to fire again in 1 second */
    mod_timer(&my_timer, jiffies + HZ);
}

static int __init tsc_print_init(void)
{
    printk(KERN_INFO "TSC Print Module loaded.\n");

    /* Setup the timer to fire in 1 second */
    timer_setup(&my_timer, print_tsc, 0);
    mod_timer(&my_timer, jiffies + HZ);

    return 0;
}

static void __exit tsc_print_exit(void)
{
    del_timer(&my_timer);
    printk(KERN_INFO "TSC Print Module unloaded.\n");
}

module_init(tsc_print_init);
module_exit(tsc_print_exit);
