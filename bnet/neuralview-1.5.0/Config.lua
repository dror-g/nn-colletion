return {
    -- training report limits
    limits = {
        snapshots = 100,
        mse = 10000,
        bit = 10000,
    },
    
    -- gnuplot parameters
    plot = {
        bin = 'gnuplot',
        font = '"DejaVuSansMono,10"',
        
        -- Used to force the names of the temporary plot files
        --tmpimg = 'tmp.png',
        --tmpdata = 'tmp.data',
    },
}
